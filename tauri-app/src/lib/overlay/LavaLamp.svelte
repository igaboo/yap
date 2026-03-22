<script lang="ts">
  /**
   * Lava lamp gradient using CSS radial-gradients.
   * Blobs move as a group (shared drift) with small individual offsets.
   */

  let { energy = 0.5, visible = true }: { energy?: number; visible?: boolean } = $props();

  let t = $state(0);
  let animId = 0;
  let startTime = 0;

  const blobs = [
    { color: '147, 51, 234',  offsetX: -8,  offsetY: -3,  size: 220, scale: 1.0  },  // purple
    { color: '59, 130, 246',  offsetX:  5,  offsetY:  2,  size: 260, scale: 0.9  },  // blue
    { color: '34, 211, 238',  offsetX: -4,  offsetY:  4,  size: 190, scale: 0.85 },  // cyan
    { color: '99, 102, 241',  offsetX:  7,  offsetY: -2,  size: 240, scale: 0.9  },  // indigo
  ];

  let blobStyles = $derived.by(() => {
    const speed = 0.4 + energy * 0.6;
    const brightness = 0.5 + energy * 0.4;

    // Shared group motion — all blobs drift together
    const groupX = Math.cos(t * 0.3 * speed) * 8;
    const groupY = Math.sin(t * 0.2 * speed) * 4;

    return blobs.map((b, i) => {
      // Small individual wiggle on top of group motion
      const wiggleX = Math.sin(t * (0.5 + i * 0.15) + i * 1.5) * 4;
      const wiggleY = Math.cos(t * (0.4 + i * 0.12) + i * 2.0) * 3;

      const x = 50 + groupX + b.offsetX + wiggleX;
      // y=90% puts blobs mostly off-screen at bottom, peeking up behind the pill
      const y = 90 + groupY + b.offsetY + wiggleY;

      const alpha = brightness * b.scale;
      return `radial-gradient(ellipse ${b.size}px ${b.size * 0.55}px at ${x}% ${y}%, rgba(${b.color}, ${alpha.toFixed(2)}) 0%, rgba(${b.color}, 0) 70%)`;
    });
  });

  function loop(timestamp: number) {
    if (!startTime) startTime = timestamp;
    t = (timestamp - startTime) / 1000;
    animId = requestAnimationFrame(loop);
  }

  $effect(() => {
    if (visible) {
      startTime = 0;
      animId = requestAnimationFrame(loop);
    } else {
      if (animId) cancelAnimationFrame(animId);
      animId = 0;
    }
    return () => {
      if (animId) cancelAnimationFrame(animId);
    };
  });
</script>

<div
  class="lava-lamp"
  style="
    opacity: {visible ? 1 : 0};
    background: {blobStyles.join(', ')};
  "
></div>

<style>
  .lava-lamp {
    position: absolute;
    inset: 0;
    pointer-events: none;
    transition: opacity 800ms ease-in-out;
    filter: blur(40px);
  }
</style>
