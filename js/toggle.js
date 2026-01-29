document.addEventListener('DOMContentLoaded', () => {
  const humanToggle = document.querySelector('.human-toggle');
  const profilePhoto = document.querySelector('.profile-photo');
  let isShowingPhoto = false;
  const profilePhotoUrl = 'images/profile.jpg';

  // Store original wolf sources
  const wolfSources = {
    dark: 'images/wolf-white.svg',
    light: 'images/wolf-white.svg'
  };

  const prefetchProfilePhoto = () => {
    const img = new Image();
    img.decoding = 'async';
    if ('fetchPriority' in img) img.fetchPriority = 'low';
    img.src = profilePhotoUrl;
    if (typeof img.decode === 'function') img.decode().catch(() => {});
  };

  window.addEventListener(
    'load',
    () => {
      if (typeof window.requestIdleCallback === 'function') {
        window.requestIdleCallback(prefetchProfilePhoto, { timeout: 2000 });
      } else {
        setTimeout(prefetchProfilePhoto, 0);
      }
    },
    { once: true }
  );

  humanToggle.addEventListener('click', (e) => {
    e.preventDefault();
    isShowingPhoto = !isShowingPhoto;

    if (isShowingPhoto) {
      // Show photo
      profilePhoto.innerHTML = `<img src="${profilePhotoUrl}" alt="Riley Kivimäki">`;
    } else {
      // Show wolf
      profilePhoto.innerHTML = `
        <source srcset="${wolfSources.dark}" media="(prefers-color-scheme: dark)">
        <img src="${wolfSources.light}" alt="Wolp">
      `;
    }
  });
});
