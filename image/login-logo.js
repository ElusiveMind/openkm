// FlyingFlip Studios credit under the KCenter login card.
//
// KCenter is the single-page app that /openkm/ redirects to. It renders its
// login view in the browser, so this script is inlined into kcenter/index.html
// by brand-login.sh at build time. It waits for the login card to appear,
// stacks the column it sits in, and adds the credit line under the card: the
// text "Docker image environment provided by" with the logo to its right,
// vertically centered. The block leaves with the login view and comes back
// with it.
(function () {
  var base = window.location.pathname.replace(/\/kcenter\/.*$/, '');
  var logo = base + '/img/flyingflip.png';

  function place() {
    var card = document.querySelector('.okm-loginCard');
    if (!card || document.getElementById('ff-credit')) {
      return;
    }
    var column = card.parentElement;
    if (column && column.classList.contains('d-flex')) {
      column.classList.add('flex-column');
    }
    var credit = document.createElement('div');
    credit.id = 'ff-credit';
    credit.className = 'mt-4 d-flex flex-wrap align-items-center justify-content-center text-center';
    // Sized to its content so text and logo share one line even where the
    // login column is narrower; wraps below about 470px of viewport.
    credit.style.width = 'max-content';
    credit.style.maxWidth = 'calc(100vw - 2rem)';
    var label = document.createElement('span');
    label.className = 'text-muted mx-2';
    label.textContent = 'Docker image environment provided by';
    var link = document.createElement('a');
    link.href = 'https://www.flyingflip.com';
    link.target = '_blank';
    link.rel = 'noopener';
    link.title = 'FlyingFlip Studios';
    link.className = 'd-inline-flex mx-2';
    var img = document.createElement('img');
    img.src = logo;
    img.alt = 'FlyingFlip Studios';
    img.width = 196;
    img.height = 60;
    link.appendChild(img);
    credit.appendChild(label);
    credit.appendChild(link);
    card.insertAdjacentElement('afterend', credit);
  }

  function start() {
    var root = document.getElementById('app') || document.body;
    new MutationObserver(place).observe(root, { childList: true, subtree: true });
    place();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }
})();
