# VoiceType 🎙️

Hold a key, speak, release — your words are transcribed and pasted wherever you're typing. Like Wispr Flow, but free and open source.

## Features

- **Hold-to-record** — fn or Option key
- **On-device transcription** — Apple Speech, no API key needed
- **AI formatting** — optional, bring your own key (OpenAI or Anthropic)
- **Four modes** — Verbatim, Casual, Formatted, Professional
- **Floating overlay** — pill indicator shows recording/processing state
- **Zero dependencies** — pure Swift, ~1300 lines

## Install

```bash
git clone https://github.com/igaboo/voicetype.git
cd voicetype
chmod +x build.sh && ./build.sh
cp -r build/VoiceType.app /Applications/
open /Applications/VoiceType.app
```

Requires Xcode Command Line Tools (`xcode-select --install`) and macOS 12+.

First launch will prompt for **Microphone**, **Speech Recognition**, and **Accessibility** permissions — grant all three.

## Settings

Click the mic icon in the menu bar → **Settings** (⌘,) to configure:

- **Hotkey** — fn or Option
- **Formatting mode** — Verbatim, Casual, Formatted, or Professional
- **AI provider** — None, OpenAI, or Anthropic (API key required for formatting)

## Update

```bash
cd voicetype && git pull
./build.sh && cp -r build/VoiceType.app /Applications/
pkill -f VoiceType; open /Applications/VoiceType.app
```

## License

MIT
