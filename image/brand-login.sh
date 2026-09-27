#!/bin/bash
#
# Build-time step. Places a credit line under the login box of OpenKM 7.0:
# "Docker image environment provided by" followed by the FlyingFlip Studios
# logo, which links to https://www.flyingflip.com.
#
# OpenKM 7.0 has two login pages that look the same:
#   - /openkm/kcenter/login, the KCenter single-page app that /openkm/
#     redirects to. Its login view is rendered in the browser, so its shell
#     page kcenter/index.html gets an inline script (login-logo.js) that adds
#     the logo block once the card is on screen.
#   - /openkm/login, the server-side login_desktop.jsp used by the classic
#     desktop and the administration pages. It gets the block (login-logo.html)
#     inserted after the card.
#
# The installer leaves OpenKM packed as a war that Tomcat unpacks on the
# first start, so both changes are made inside the war, and the logo is
# added under img/, which OpenKM serves without a login. Called from the
# Dockerfile after setup.sh.
#
# Every patch anchors on markup of the stock 7.0.3 pages and refuses to
# build if an anchor is missing, so a future OpenKM release cannot silently
# ship without the logo or with a broken page.
#

set -euo pipefail

TOMCAT=/opt/tomcat
WAR="$TOMCAT/webapps/openkm.war"
LOGO_SRC=/opt/flyingflip.png
LOGO_PATH=img/flyingflip.png
JSP_SNIPPET=/opt/login-logo.html
KCENTER_SCRIPT=/opt/login-logo.js

if [[ ! -f "$WAR" ]]; then
  echo "OpenKM war not found at $WAR." >&2
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

unzip -q "$WAR" login_desktop.jsp kcenter/index.html

#
# login_desktop.jsp
#
# The login card sits in a flex row that centers it on the page. Make that
# row a column so the logo stacks under the card instead of beside it.
COLUMN='d-flex align-items-center justify-content-center"'
if [[ "$(grep -c "$COLUMN" login_desktop.jsp)" -ne 1 ]]; then
  echo "login_desktop.jsp: expected exactly one login column ($COLUMN)." >&2
  exit 1
fi
sed -i "s/$COLUMN/d-flex flex-column align-items-center justify-content-center\"/" login_desktop.jsp

# Insert the logo block after the card, whose last content is the
# "Powered by OpenKM" link followed by the card-footer and card closing tags.
if [[ "$(grep -c 'Powered by OpenKM</a>' login_desktop.jsp)" -ne 1 ]]; then
  echo "login_desktop.jsp: expected exactly one 'Powered by OpenKM' link." >&2
  exit 1
fi
SNIPPET="$JSP_SNIPPET" perl -0pi -e '
  BEGIN { local $/; open(my $fh, "<", $ENV{SNIPPET}) or die "cannot read $ENV{SNIPPET}: $!"; $snippet = <$fh>; close $fh; }
  $count = s{(Powered by OpenKM</a>\s*</div>\s*</div>\n)}{$1$snippet};
  END { die "login_desktop.jsp: card closing tags not found after the Powered by OpenKM link\n" unless $count == 1; }
' login_desktop.jsp

#
# kcenter/index.html
#
# The shell is a one-line file that ends with the app's script tags. Inline
# the logo script just before </body> so it runs after the app has loaded.
if [[ "$(grep -o '</body>' kcenter/index.html | wc -l)" -ne 1 ]]; then
  echo "kcenter/index.html: expected exactly one </body>." >&2
  exit 1
fi
if grep -q 'ff-credit' kcenter/index.html; then
  echo "kcenter/index.html: already carries the logo script." >&2
  exit 1
fi
SCRIPT="$KCENTER_SCRIPT" perl -0pi -e '
  BEGIN { local $/; open(my $fh, "<", $ENV{SCRIPT}) or die "cannot read $ENV{SCRIPT}: $!"; $script = <$fh>; close $fh; }
  $count = s{</body>}{<script>\n$script</script></body>};
  END { die "kcenter/index.html: </body> not replaced\n" unless $count == 1; }
' kcenter/index.html

#
# Logo file and war update
#
mkdir -p "$(dirname "$LOGO_PATH")"
cp "$LOGO_SRC" "$LOGO_PATH"

# zip replaces existing entries with the same name and adds new ones.
zip -q "$WAR" login_desktop.jsp kcenter/index.html "$LOGO_PATH"

# Confirm the war now carries all three changes.
unzip -p "$WAR" login_desktop.jsp | grep -q 'flyingflip.png' || { echo "login_desktop.jsp in the war was not updated." >&2; exit 1; }
unzip -p "$WAR" kcenter/index.html | grep -q 'ff-credit' || { echo "kcenter/index.html in the war was not updated." >&2; exit 1; }
unzip -l "$WAR" "$LOGO_PATH" > /dev/null || { echo "$LOGO_PATH missing from the war." >&2; exit 1; }

echo "Login pages branded: $LOGO_PATH added, login_desktop.jsp and kcenter/index.html patched in $WAR"
