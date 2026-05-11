function canPlayAudio() {
  return typeof window !== "undefined" && typeof window.Audio !== "undefined";
}

export function playUiSound(src: string) {
  if (!canPlayAudio()) {
    return;
  }

  try {
    const sound = new window.Audio(src);
    sound.volume = 0.45;
    void sound.play().catch(() => {});
  } catch {
    // Ignore sound playback failures to keep the UI responsive.
  }
}
