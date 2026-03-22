<script lang="ts">
  /**
   * Lava lamp gradient using CSS radial-gradient divs instead of Canvas.
   * Canvas ctx.filter='blur()' silently fails on WebKit in transparent windows.
   * CSS approach is simpler and guaranteed to render.
   */

  let { energy = 0.5, visible = true }: { energy?: number; visible?: boolean } = $props();

  let t = $state(0);
  let animId = 0;
  let startTime = 0;

  const blobs = [
    { color: '147, 51, 234',  xFreq: 0.7,  yFreq: 0.5,  xAmp: 25, yAmp: 12, xPhase: 0,   yPhase: 0,   size: 200, scale: 1.0 },
    { color: '59, 130, 246',  xFreq: 0.6,  yFreq: 0.45, xAmp: 30, yAmp: 14, xPhase: 1.5, yPhase: 1.0, size: 240, scale: 0.9, useSin: true },
    { color: '34, 211, 238',  xFreq: 0.8,  yFreq: 0.6,  xAmp: 20, yAmp: 10, xPhase: 3.0, yPhase: 2.0, size: 180, scale: 0.85 },
    { color: '99, 102, 241',  xFreq: 0.55, yFreq: 0.7,  xAmp: 28, yAmp: 12, xPhase: 4.5, yPhase: 3.5, size: 220, scale: 0.9, useSin: true },
  ];

  // Computed blob positions (reactive)
  let blobStyles = $derived.by(() => {
    const speed = 0.4 + energy * 0.6;
    const brightness = 0.5 + energy * 0.4;

    return blobs.map(b => {
      const xFn = b.useSin ? Math.sin : Math.cos;
      const yFn = b.useSin ? Math.cos : Math.sin;
      const x = 50 + xFn(t * b.xFreq * speed + b.xPhase) * b.xAmp;
      const y = 70 + yFn(t * b.yFreq * speed + b.yPhase) * b.yAmp;
      const alpha = brightness * b.scale;
      return `radial-gradient(ellipse ${b.size}px ${b.size * 0.5}px at ${x}% ${y}%, rgba(${b.color}, ${alpha.toFixed(2)}) 0%, rgba(${b.color}, 0) 70%)`;
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
