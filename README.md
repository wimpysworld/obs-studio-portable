<h1 align="center">
  <img src="https://avatars1.githubusercontent.com/u/7725691?v=3&s=256" alt="OBS Studio">
  <br />
  OBS Studio <i>Portable</i> for Ubuntu
</h1>

<p align="center"><b>Portable builds of OBS Studio for Ubuntu that come pre-loaded with extra features and plugins for live streaming and screen recording</b>
<br />
Made with 💝 for <img src=".github/ubuntu.png" align="top" width="18" /></p>

# OBS Studio Portable for Ubuntu

**Running OBS Studio in Portable Mode means that all settings (Profiles and Scene
Collections) are saved within the same directory tree as the OBS Studio
executables, plugins and. You can copy the whole folder to a another computer
and just use it.**

  - Nearly 40 of the best 3rd Party plugins for OBS Studio are bundled
  - Chromium Embedded Frameworks (CEF) to enable Browser Sources
  - NVENC (NVIDIA) and VA-API (AMD & Intel) accelerated video encoding
  - Fraunhofer FDK AAC Codec
  - VLC and GStreamer Media sources
  - AJA NTV2 SDK

## Supported Software

Each tarball of OBS Studio Portable includes a `manifest.txt` that describes
exactly which versions of plugins and add-ons are included.

| Distro       | OBS Studio 26 | OBS Studio 27 | OBS Studio 28 |
| ------------ | ------------- | ------------- | ------------- |
| Ubuntu 20.04 | 26.1.2 (Qt 5) | 27.2.4 (Qt 5) | 28.0.2 (Qt 5) |
| Ubuntu 22.04 | 26.1.2 (Qt 5) | 27.2.4 (Qt 5) | 28.0.2 (Qt 6) |
| Ubuntu 22.10 |               |               | 28.0.2 (Qt 6) |

### Caveats

  - [Game Capture](https://github.com/nowrep/obs-vkcapture) is available in Ubuntu 22.04 (and newer) builds.
  - [NvFBC Capture](https://gitlab.com/fzwoch/obs-nvfbc) is available in OBS Studio 26 and 27 builds; the required GLX support was removed in OBS Studio 28.
  - PipeWire support is available in Ubuntu 22.04 (and newer) builds.
  - [Teleport](https://github.com/fzwoch/obs-teleport) is available in Ubuntu 22.04 (and newer) builds.
  - [SRT & RIST Protocol](https://obsproject.com/wiki/Streaming-With-SRT-Or-RIST-Protocols) support is available in 22.10 and newer
  - [WebSockets](https://github.com/obsproject/obs-websocket) 5.0.1 and 4.9.1-compat are included in OBS Studio 28 builds

# Install

You can safely install these OBS Studio Portable builds alongside `.deb`,
FlatPak or Snap installs of OBS Studio.

The install process is simple:

  - Download the tarball (and sha256 hash) of OBS Studio for the version of Ubuntu you're running.
    - **Builds are specific to an Ubuntu release!**
  - Extract the tarball somewhere.
  - Run `obs-dependencies`, include in the tarball, to make sure the runtime requirements for OBS Studio are satisfied.
  - Run `obs-portable` to launch OBS Studio.
    - **It is essential you use `obs-portable` to launch OBS Studio** to ensure it finds all the associated libraries and add-ons.

```bash
wget "https://github.com/wimpysworld/obs-studio-portable/releases/download/r22274/obs-portable-28.0.2-r22274-ubuntu-$(lsb_release -rs).tar.bz2"
wget "https://github.com/wimpysworld/obs-studio-portable/releases/download/r22274/obs-portable-28.0.2-r22274-ubuntu-$(lsb_release -rs).tar.bz2.sha256"
sha256sum -c obs-portable-28.0.2-r22274-ubuntu-$(lsb_release -rs).tar.bz2.sha256
tar xvf obs-portable-28.0.2-r22274-ubuntu-$(lsb_release -rs).tar.bz2
cd obs-portable-28.0.2-r22274-ubuntu-$(lsb_release -rs)
sudo ./obs-dependencies
./obs-portable
```

## Upgrades

The upgrade process is the same as an install and you can simply copy the
`config` folder from your old OBS Studio Portable directory to the new one. If
anything doesn't correctly when you start the new OBS Studio, just keep using
the previous OBS Studio Portable instance.

# Why does this project exist?

If any of the following is true for you, you might find these builds of OBS
Studio useful.

 - **I want a version of OBS Studio for Ubuntu that has all the features enabled, *by default***
   - I use lots of 3rd party OBS Studio plugins in my stream configuration.
 - **I stream from two different locations using multiple computers**
   - [Syncthing](https://syncthing.net/) sync my streaming configuration between sites, but I'd like to include OBS Studio itself.
 - **I make changes to my OBS Studio configuration from various computers**
   - Keeping these changes in sync manually can be cumbersome. But now I can automate that with [Syncthing](https://syncthing.net/) and Portable OBS Studio.
 - **I stream to multiple channels**
   - Having discrete OBS Studio instances is easier to work with than switching between dozens of Profile and Scene Collection combinations.
 - **I don't want to deal with flag day releases of new software**
   - New software is wonderful, but want to control when and how I upgrade each of my streaming configuration instances.
 - **My stream integrations are not (currently) compatible with confined packages of OBS Studio**
   - I have some funky stream integrations, and will likely create more.
 - **I sometimes stream how to do stuff with OBS Studio**
   - Being able to run *"demo"* instances of OBS Studio with isolated configurations is great for this.
 - **I want a stable OBS setup and an in-development OBS setup**
   - When developing new features for my stream, I want to freely experiment with new versions of OBS Studio and it's plugins without fear of disrupting my stable setup.
 - **I sometimes need old and new versions of OBS Studio available**
   - I have some streaming projects that are archived and do not need upgrading, but I do want to reference them from time to time.

# Batteries included

I am extremely thankful to the OBS Studio developers and developers of the
growing list of excellent plugins. These Portable build of OBS Studio for Ubuntu
celebrate the best of what's available. Thank you! 🙇

Here are the 3rd party plugins that come bundled with OBS Studio Portable for
Ubuntu:

## Audio 🔉

  * **[Audio Pan](https://github.com/norihiro/obs-audio-pan-filter)** plugin; control stereo pan of audio source.
  * **[MIDI](https://github.com/nhielost/obs-midi-mg)** plugins; allows MIDI devices to interact with OBS Studio.
  * **[Mute Filter](https://github.com/norihiro/obs-mute-filter)** plugin; to mute audio of a source.
  * **[PipeWire Audio Capture](https://github.com/dimtpap/obs-pipewire-audio-capture)** plugin; capture application audio from PipeWire.
  * **[Scale to Sound](https://github.com/Qufyy/obs-scale-to-sound)** plugin; adds a filter which makes a source scale based on the audio levels of any audio source you choose
  * **[Soundboard](https://github.com/cg2121/obs-soundboard)** plugin; adds a soundboard dock.
  * **[Waveform](https://github.com/phandasm/waveform)** plugin; audio spectral analysis.

## Automation 🎛

  * **[Advanced Scene Switcher](https://github.com/WarmUpTill/SceneSwitcher)** plugin; an automated scene switcher.
  * **[Directory Watch Media](https://github.com/exeldro/obs-dir-watch-media)** plugin; filter you can add to media source to load the oldest or newest file in a directory.
  * **[Dummy Source](https://github.com/norihiro/obs-command-source)** plugin; provides a dummy source to execute arbitrary commands when scene is switched.
  * **[Source Switcher](https://github.com/exeldro/obs-source-switcher)** plugin; to switch between a list of sources.
  * **[Transition Table](https://github.com/exeldro/obs-transition-table)** plugin; customize scene transitions.
  * **[Websockets](https://github.com/Palakis/obs-websocket)** plugin; remote-control OBS Studio through WebSockets.
    * **Also includes the *4.91 compatibility* version**

## Effects ✨

  * **[DVD Screensaver](https://github.com/univrsal/dvds3)** plugin; a DVD screen saver source type.
  * **[Downstream Keyer](https://github.com/exeldro/obs-downstream-keyer)** plugin; add a Downstream Keyer dock.
  * **[Dynamic Delay](https://github.com/exeldro/obs-dynamic-delay)** plugin; filter for dynamic delaying a video source.
  * **[Face Tracker](https://github.com/norihiro/obs-face-tracker)** plugin; face tracking plugin
  * **[Freeze Filter](https://github.com/exeldro/obs-freeze-filter)** plugin; freeze a source using a filter.
  * **[Gradient Source](https://github.com/exeldro/obs-gradient-source)** plugin; adding gradients as a Source.
  * **[Move Transition](https://github.com/exeldro/obs-move-transition)** plugin; move source to a new position during scene transition.
  * **[Multi Source Effect](https://github.com/norihiro/obs-multisource-effect)** plugin; provides a custom effect to render multiple sources.
  * **[Recursion Effect](https://github.com/exeldro/obs-recursion-effect)** plugin; recursion effect filter.
  * **[Replay Source](https://github.com/exeldro/obs-replay-source)** plugin; slow motion replay async sources from memory.
  * **[RGB Levels](https://github.com/petrifiedpenguin/obs-rgb-levels-filter)** plugin; simple filter to adjust RGB levels.
  * **[Time Shift](https://github.com/exeldro/obs-time-shift)** plugin;  time shift a source using a filter.
  * **[Time Warp Scan](https://github.com/exeldro/obs-time-warp-scan)** plugin; a time warp scan filter.

## Encoding & Output 🎞

  * **[Game Capture](https://github.com/nowrep/obs-vkcapture)** plugin; Vulkan/OpenGL game capture.
  * **[GStreamer](https://github.com/fzwoch/obs-gstreamer)** plugin; feed GStreamer launch pipelines into OBS Studio.
  * **[NvFBC](https://gitlab.com/fzwoch/obs-nvfbc)** plugin; screen capture via NVIDIA FBC API. Requires [NvFBC patches for Nvidia drivers](https://github.com/keylase/nvidia-patch) for consumer grade GPUs.
  * **[Source Record](https://github.com/exeldro/obs-source-record)** plugin; make sources available to record via a filter.
  * **[StreamFX](https://github.com/Xaymar/obs-StreamFX)** plugin; unlocks the full potential of NVENC along with useful composition filters.
  * **[Teleport](https://github.com/fzwoch/obs-teleport)** plugin; open NDI-like replacement. (*not NDI compatible*)
  * **[VAAPI](https://github.com/exeldro/obs-transition-table)** plugin; GStreamer based VAAPI encoder implementation.
  * **[Virtual Cam Filter](https://github.com/exeldro/obs-virtual-cam-filter)** plugin; make sources available to the virtual camera via a filter.

## Tools 🛠

  * **[Color Monitor](https://github.com/norihiro/obs-color-monitor)** plugin; vectorscope, waveform, and histogram.
  * **[Scene Collection Manager](https://github.com/exeldro/obs-scene-collection-manager)** plugin; filter, backup and restore Scene Collections.
  * **[Scene Notes Dock](https://github.com/exeldro/obs-scene-notes-dock)** plugin; create a Dock for showing and editing notes for the current active scene.
  * **[Source Copy](https://github.com/exeldro/obs-source-copy)** plugin; adds copy and paste options to the tools menu.
  * **[Source Dock](https://github.com/exeldro/obs-source-dock)** plugin; create a Dock for a source, which lets you see audio levels, change volume and control media.

## Text 📝

  * **[Text Pango](https://github.com/kkartaltepe/obs-text-pango)** plugin; Provides a text source rendered using Pango with multi-language support, emoji support, vertical rendering and RTL support.
  * **[Text PThread](https://github.com/norihiro/obs-text-pthread)** plugin; Rich text source plugin with many advanced features.

### Additional plugins

If the builds of OBS Studio offered here don't include a plugin that you use,
you can download a pre-compiled version and add it to the portable folder:

  - Put any `.so` files in `obs-plugins/64bit`
  - Put any data files associated with the plugin in `data/obs-plugins/<plugin name>/`

## OBS Virtual Camera

OBS Studio Virtual Camera support is integrated. The `Start Virtual Camera`
button is located in the Controls pane, just below `Start Recording`. Here's how
to install and configure `v4l2loopback` which OBS uses:

```bash
echo 'options v4l2loopback devices=1 video_nr=13 card_label="OBS Virtual Camera" exclusive_caps=1' | sudo tee /etc/modprobe.d/v4l2loopback.conf
echo "v4l2loopback" | sudo tee /etc/modules-load.d/v4l2loopback.conf
sudo modprobe -r v4l2loopback
sudo modprobe v4l2loopback devices=1 video_nr=13 card_label="OBS Virtual Camera" exclusive_caps=1
```

**NOTE!** Using `video_nr` greater than 64 will not work.

# Wayland

Browser docks and streaming service integrations are currently disabled on
Wayland due to Chromium Embedded Framework (CEF) issues. If you need browser
docks or stream service integrations, click on the cog icon when logging into
Ubuntu and select "ubuntu on xorg".

Alternatively you can coerce OBS Studio to run via Xwayland without changing the
desktop session:

```bash
env QT_QPA_PLATFORM=xcb ./obs-portable
```

# Build process 🏗

Each build is compiled in a freshly provisioned systemd container. The, somewhat
hastily thrown together, *"build scripts"* are included in this repository.

The `build-*.sh` scripts are wrappers to help automate things, with
[`build-auto.sh`](./build-auto.sh) being the main entry point.

The actual build script, [`obs-portable.sh`](builder/obs-portable.sh), gets
injected into the new container and is responsible for actually building OBS
Studio. Perhaps it might also serve as a reference for users of other Linux
distributions who want to create their own portable builds of OBS Studio.

## Release numbers

An OBS Studio Portable for Ubuntu release number will be something like r22271,
and the filename will clearly indicate the version of OBS Studio and which
Ubuntu is it for:

> obs-portable-28.0.2-r22271-ubuntu-22.04.tar.bz2

The purpose of the release number is to indicate a revision to the composition
of the portable bundle, most likely due to adding/updating the bundled 3rd party
plugins.
# References

  - https://obsproject.com/wiki/Build-Instructions-For-Linux
  - https://github.com/snapcrafters/obs-studio
  - https://launchpad.net/~obsproject
