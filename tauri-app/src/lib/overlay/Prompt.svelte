<script lang="ts">
  type Variant = 'card' | 'inline-hold';

  let {
    variant,
    step,
    text = '',
    hotkeyLabel = 'fn',
  }: {
    variant: Variant;
    step: string | null;
    text?: string;
    hotkeyLabel?: string;
  } = $props();

  let holdPromptText = $derived(step === 'welcome' ? 'to finish' : 'to continue');
  let isNice = $derived(step === 'nice');
</script>

{#if variant === 'inline-hold'}
  <div class="hold-prompt">
    <span>Hold</span>
    <span class="keycap">{hotkeyLabel}</span>
    <span>{holdPromptText}</span>
  </div>
{:else if text && step}
  <div class="onboarding-card animate-card-enter" class:nice-card={isNice}>
    {@html text}
  </div>
{/if}
