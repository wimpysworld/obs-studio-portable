<h1 align="center">
  <img src="https://avatars1.githubusercontent.com/u/7725691?v=3&s=256" alt="OBS Studio">
  <br />
  OBS Studio <i>Portable</i> for Ubuntu
</h1>

<p align="center"><b>Portable builds of OBS Studio for Ubuntu, pre-loaded with extra features and plugins for live streaming and screen recording</b>
<br />
Made with 💝 for <img src=".github/ubuntu.png" align="top" width="18" /></p>

# OBS Studio Portable for Ubuntu

**Running OBS Studio in Portable Mode means that all settings (Profiles and Scene Collections) are saved within the same directory tree as the OBS Studio executables, plugins and configuration. You can copy the whole folder to another computer and just use it.**

  - Over 45 of the best 3rd Party plugins for OBS Studio are bundled!
  - Chromium Embedded Frameworks (CEF) to enable Browser Sources
  - NVENC (NVIDIA) and VA-API (AMD & Intel) accelerated video encoding
  - Fraunhofer FDK AAC Codec
  - VLC and GStreamer Media sources
  - AJA NTV2 SDK

## Supported Software

The tarball of OBS Studio Portable includes a `manifest.txt` that describes exactly which versions of plugins and add-ons are included.

|              | OBS Studio 29 |
| ------------ | ------------- |
| Ubuntu 20.04 | 29.0.2 (Qt 5) |
| Ubuntu 22.04 | 29.0.2 (Qt 6) |
| Ubuntu 22.10 | 29.0.2 (Qt 6) |
| Ubuntu 23.04 | 29.0.2 (Qt 6) |
| Plugins      | 46            |

### Caveats

  - [Game Capture](https://github.com/nowrep/obs-vkcapture) is available on Ubuntu 22.04 and newer.
  - [NvFBC Capture](https://gitlab.com/fzwoch/obs-nvfbc) is available in legacy builds of OBS Studio 26 and 27 builds; the required GLX support was removed in OBS Studio 28.
  - PipeWire support is available in Ubuntu 22.04 and newer.
  - [Teleport](https://github.com/fzwoch/obs-teleport) is available on Ubuntu 22.04 and newer.
  - [SRT & RIST Protocol](https://obsproject.com/wiki/Streaming-With-SRT-Or-RIST-Protocols) support is available on Ubuntu 22.10 and newer.
  - [WebSockets](https://github.com/obsproject/obs-websocket) 5.0.1 and 4.9.1-compat are included in OBS Studio 28 and newer.
    - *Legacy builds of OBS Studio 26 have 4.9.0 and OBS Studio 27 builds have 4.9.1*

# Install

You can safely install these OBS Studio Portable builds alongside `.deb`,
FlatPak or Snap installs of OBS Studio.

## Command Line

The install process is simple:

  - **[Download the tarball (and sha256 hash) of OBS Studio Portable](https://github.com/wimpysworld/obs-studio-portable/releases)** for the version of Ubuntu you're running.
    - **Builds are specific to an Ubuntu release!**
  - Extract the tarball somewhere.
  - Run `obs-dependencies`, included in the tarball, to make sure the runtime requirements for OBS Studio are satisfied.
  - Run `obs-portable` to launch OBS Studio.
    - **You use the `obs-portable` launcher** to ensure OBS Studio finds all the associated libraries and add-ons.

```bash
wget "https://github.com/wimpysworld/obs-studio-portable/releases/download/r23090/obs-portable-29.0.2-r23090-ubuntu-$(lsb_release -rs).tar.bz2"
wget "https://github.com/wimpysworld/obs-studio-portable/releases/download/r23090/obs-portable-29.0.2-r23090-ubuntu-$(lsb_release -rs).tar.bz2.sha256"
sha256sum -c obs-portable-29.0.2-r23090-ubuntu-$(lsb_release -rs).tar.bz2.sha256
tar xvf obs-portable-29.0.2-r23090-ubuntu-$(lsb_release -rs).tar.bz2
cd obs-portable-29.0.2-r23090-ubuntu-$(lsb_release -rs)
sudo ./obs-dependencies
./obs-portable
```

## Graphical Install

Or if you prefer a graphical interface, you can use [**the fabulous QuickOBS**](https://github.com/ymauray/quickobs) ✨ from the always wonderful [Yannick Mauray](https://github.com/frenchguych) 💖

## Upgrades

The upgrade process is the same as an install and you can simply copy the `config` folder from your old OBS Studio Portable directory to the new one. If anything doesn't correctly when you start the new OBS Studio, just keep using the previous OBS Studio Portable instance.

[QuickOBS](https://github.com/ymauray/quickobs) includes a feature to save and restore your configurations too.

# Why does this project exist?

If any of the following are true for you, you might find these builds of OBS Studio useful.

 - **I want a version of OBS Studio for Ubuntu that has all the features enabled, *by default***
   - I use lots of 3rd party OBS Studio plugins in my stream configuration.
 - **I stream from two different locations using multiple computers**
   - [Syncthing](https://syncthing.net/) syncs my streaming configuration between sites. I'd also like to include OBS Studio itself.
 - **I make changes to my OBS Studio configuration from various computers**
   - Keeping these changes in sync manually can be cumbersome.
 - **I stream to multiple channels**
   - Having discrete OBS Studio instances is easier to work with than switching between dozens of Profile and Scene Collection combinations.
 - **I don't want to deal with flag day releases of new software**
   - New software is wonderful, but want to control when and how I upgrade each of my streaming configuration instances.
 - **My stream integrations are not (currently) compatible with packages of OBS Studio that use confinement**
   - I have some funky stream integrations, and will likely create more. I don't want to limit my creative options.
 - **I sometimes stream OBS Studio how-tos and examples**
   - Being able to run demo instances (at will) of OBS Studio with isolated configurations is great for this.
 - **I want a stable OBS setup and an in-development OBS setup**
   - When developing new features for my stream, I want to freely experiment with new versions of OBS Studio and its plugins without fear of disrupting my stable setup.
 - **I sometimes need old versions of OBS Studio**
   - I have some streaming projects that are archived and don't need upgrading. But I do want to reference them from time to time.

# Batteries included

I'm extremely thankful to the OBS Studio developers and developers of the growing list of excellent plugins. These Portable builds of OBS Studio for Ubuntu celebrate the best of what's available. Thank you! 🙇

Here are the 3rd party plugins that come bundled with OBS Studio Portable for Ubuntu:

## Audio 🔉

  * **[Audio Pan](https://github.com/norihiro/obs-audio-pan-filter)** plugin; control stereo pan of audio sources.
  * **[MIDI](https://github.com/nhielost/obs-midi-mg)** plugins; allows MIDI devices to interact with OBS Studio.
  * **[Mute Filter](https://github.com/norihiro/obs-mute-filter)** plugin; to mute audio from a source.
  * **[PipeWire Audio Capture](https://github.com/dimtpap/obs-pipewire-audio-capture)** plugin; capture application audio from PipeWire.
  * **[Scale to Sound](https://github.com/Qufyy/obs-scale-to-sound)** plugin; adds a filter which makes a source scale based on the audio levels of any audio source you choose
  * **[Soundboard](https://github.com/cg2121/obs-soundboard)** plugin; adds a soundboard dock.
  * **[Waveform](https://github.com/phandasm/waveform)** plugin; audio spectral analysis.

## Automation 🎛

  * **[Advanced Scene Switcher](https://github.com/WarmUpTill/SceneSwitcher)** plugin; an automated scene switcher.
  * **[Directory Watch Media](https://github.com/exeldro/obs-dir-watch-media)** plugin; filter you can add to a media source to load the oldest or newest file in a directory.
  * **[Dummy Source](https://github.com/norihiro/obs-command-source)** plugin; provides a dummy source to execute arbitrary commands when a scene is switched.
  * **[Source Switcher](https://github.com/exeldro/obs-source-switcher)** plugin; to switch between a list of sources.
  * **[Transition Table](https://github.com/exeldro/obs-transition-table)** plugin; customize scene transitions.
  * **[Websockets](https://github.com/Palakis/obs-websocket)** plugin; remote-control OBS Studio through WebSockets.

## Effects ✨

  * **[3D Effect](https://github.com/exeldro/obs-3d-effect)** plugin; 3D effect filter.
  * **[DVD Screensaver](https://github.com/univrsal/dvds3)** plugin; a DVD screen saver source type.
  * **[Downstream Keyer](https://github.com/exeldro/obs-downstream-keyer)** plugin; add a Downstream Keyer dock.
  * **[Dynamic Delay](https://github.com/exeldro/obs-dynamic-delay)** plugin; filter for dynamic delaying a video source.
  * **[Face Tracker](https://github.com/norihiro/obs-face-tracker)** plugin; face tracking plugin
  * **[Freeze Filter](https://github.com/exeldro/obs-freeze-filter)** plugin; freeze a source using a filter.
  * **[Gradient Source](https://github.com/exeldro/obs-gradient-source)** plugin; adding gradients as a Source.
  * **[Move Transition](https://github.com/exeldro/obs-move-transition)** plugin; move source to a new position during a scene transition.
  * **[Multi Source Effect](https://github.com/norihiro/obs-multisource-effect)** plugin; provides a custom effect to render multiple sources.
  * **[Recursion Effect](https://github.com/exeldro/obs-recursion-effect)** plugin; recursion effect filter.
  * **[Replay Source](https://github.com/exeldro/obs-replay-source)** plugin; slow motion replay async sources from memory.
  * **[RGB Levels](https://github.com/petrifiedpenguin/obs-rgb-levels-filter)** plugin; simple filter to adjust RGB levels.
  * **[Scene as Transition](https://github.com/andilippi/obs-scene-as-transition)** plugin; use scenes as transitions.
  * **[Shader Filter](https://github.com/exeldro/obs-shaderfilter)** plugin; for applying an arbitrary shader to a source.
  * **[Time Shift](https://github.com/exeldro/obs-time-shift)** plugin;  time shift a source using a filter.
  * **[Time Warp Scan](https://github.com/exeldro/obs-time-warp-scan)** plugin; a time warp scan filter.
  * **[Vintage Filter](https://github.com/cg2121/obs-vintage-filter)** plugin; a filter to make source black & white or sepia.

## Encoding & Output 🎞

  * **[Game Capture](https://github.com/nowrep/obs-vkcapture)** plugin; Vulkan/OpenGL game capture.
  * **[GStreamer](https://github.com/fzwoch/obs-gstreamer)** plugin; feed GStreamer launch pipelines into OBS Studio.
  * **[NvFBC](https://gitlab.com/fzwoch/obs-nvfbc)** plugin; screen capture via NVIDIA FBC API. Requires [NvFBC patches for Nvidia drivers](https://github.com/keylase/nvidia-patch) for consumer grade GPUs.
  * **[RTSP Server](https://github.com/iamscottxu/obs-rtspserver/)** plugin; RTSP server
  * **[Source Record](https://github.com/exeldro/obs-source-record)** plugin; make sources available to record via a filter.
  * **[StreamFX](https://github.com/Xaymar/obs-StreamFX)** plugin; unlocks the full potential of NVENC along with useful composition filters.
  * **[Teleport](https://github.com/fzwoch/obs-teleport)** plugin; open NDI-like replacement. (*not NDI compatible*)
  * **[VA-API](https://github.com/exeldro/obs-transition-table)** plugin; GStreamer-based VA-API encoder implementation.
  * **[Vertical Canvas](https://github.com/Aitum/obs-vertical-canvas)** plugin; make content for TikTok, YouTube Shorts, Instagram Live, and more without the fuss.
  * **[Virtual Cam Filter](https://github.com/exeldro/obs-virtual-cam-filter)** plugin; make sources available to the virtual camera via a filter.

## Tools 🛠

  * **[Color Monitor](https://github.com/norihiro/obs-color-monitor)** plugin; vectorscope, waveform, and histogram.
  * **[Scene Collection Manager](https://github.com/exeldro/obs-scene-collection-manager)** plugin; filter, backup and restore Scene Collections.
  * **[Scene Notes Dock](https://github.com/exeldro/obs-scene-notes-dock)** plugin; create a Dock for showing and editing notes for the currently active scene.
  * **[Source Clone](https://github.com/exeldro/obs-source-clone)** plugin; add source cloning
  * **[Source Copy](https://github.com/exeldro/obs-source-copy)** plugin; adds copy-and-paste options to the tools menu.
  * **[Source Dock](https://github.com/exeldro/obs-source-dock)** plugin; adds browser sources as custom docks.

## Text 📝

  * **[Text PThread](https://github.com/norihiro/obs-text-pthread)** plugin; Rich text source plugin with many advanced features including multi-language support, emoji support, vertical rendering and RTL support.

### To consider 🤔

Here are some additional plugins that look useful that I might add in the future:

  - <https://git.vrsal.xyz/alex/Durchblick>
  - <https://github.com/cg2121/obs-decklink-output-filter>
  - <https://github.com/norihiro/obs-aja-output-filter>
  - <https://github.com/norihiro/obs-async-audio-filter>
  - <https://github.com/norihiro/obs-source-record-async>
  - <https://github.com/norihiro/obs-output-filter>
  - <https://github.com/norihiro/obs-main-view-source>
  - <https://github.com/norihiro/obs-vnc>

### Additional plugins

If the builds of OBS Studio offered here don't include a plugin that you use, you can download a pre-compiled version and add it to the portable folder:

  - Put any `.so` files in `obs-plugins/64bit`
  - Put any data files associated with the plugin in `data/obs-plugins/<plugin name>/`

## OBS Virtual Camera

OBS Studio Virtual Camera support is integrated. The `Start Virtual Camera` button is located in the Controls pane, just below `Start Recording`. Here's how to install and configure `v4l2loopback` which OBS uses:

```bash
echo 'options v4l2loopback devices=1 video_nr=13 card_label="OBS Virtual Camera" exclusive_caps=1' | sudo tee /etc/modprobe.d/v4l2loopback.conf
echo "v4l2loopback" | sudo tee /etc/modules-load.d/v4l2loopback.conf
sudo modprobe -r v4l2loopback
sudo modprobe v4l2loopback devices=1 video_nr=13 card_label="OBS Virtual Camera" exclusive_caps=1
```

**NOTE!** Using `video_nr` greater than 64 will not work.

# Wayland

Browser docks and streaming service integrations are currently disabled on Wayland due to Chromium Embedded Framework (CEF) issues. If you need browser docks or stream service integrations, click on the cog icon when logging into Ubuntu and select "ubuntu on xorg".

Alternatively, you can coerce OBS Studio to run via Xwayland without changing the desktop session:

```bash
env QT_QPA_PLATFORM=xcb ./obs-portable
```

# Build process 🏗

Each build is compiled in a freshly provisioned systemd container. The, somewhat hastily thrown-together, *"build scripts"* are included in this repository.

The `build-*.sh` scripts are wrappers to help automate things, with [`build-auto.sh`](./build-auto.sh) being the main entry point.

The actual build script, [`obs-build.sh`](builder/obs-build.sh), gets injected into the new container and is responsible for actually building OBS Studio. Perhaps it might also serve as a reference for users of other Linux distributions who want to create their portable builds of OBS Studio.

## Release numbers

An OBS Studio Portable for Ubuntu release number will be something like r23090, and the filename will clearly indicate the version of OBS Studio and which Ubuntu release is it for:

```text
                     +-- OBS Portable for Ubuntu revision
                     |
                     v
obs-portable-29.0.2-r23090-ubuntu-22.04.tar.bz2
              ^                    ^
              |                    |
              +-- OBS version      +-- Supported Ubuntu release
```

The purpose of the release number is to indicate a change to the composition of the portable release; most likely due to adding/updating the bundled 3rd party plugins.

# References

  - https://obsproject.com/wiki/Build-Instructions-For-Linux
  - https://github.com/snapcrafters/obs-studio
  - https://launchpad.net/~obsproject
