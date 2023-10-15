<h1 align="center">
  <img src="https://avatars1.githubusercontent.com/u/7725691?v=3&s=256" alt="OBS Studio">
  <br />
  OBS Studio <i>Portable</i> for Ubuntu
</h1>

<p align="center"><b>Portable builds of OBS Studio for Linux, pre-loaded with extra features and plugins for live streaming and screen recording</b></p>
<p align="center">
<img alt="GitHub all releases" src="https://img.shields.io/github/downloads/wimpysworld/obs-studio-portable/total?logo=github&label=Downloads">
</p>

<p align="center">Made with 💝 for 🐧</p>

# OBS Studio Portable for Ubuntu

- Includes **50 of the best 3rd Party plugins for OBS Studio**!
- Chromium Embedded Frameworks (CEF) to enable Browser Sources
- NVENC (NVIDIA) and VA-API (AMD & Intel) accelerated video encoding
- Shader and GStreamer effects filters
- Fraunhofer FDK AAC Codec
- Pipewire application specific audio capture
- VLC and GStreamer Media sources
- AJA NTV2 SDK
- [WebSockets](https://github.com/obsproject/obs-websocket) 5.x and 4.9.1-compat are both included
- [NewTek NDI™ integration](https://github.com/obs-ndi/obs-ndi) and [Teleport](https://github.com/fzwoch/obs-teleport) support
- [SRT & RIST Protocol](https://obsproject.com/wiki/Streaming-With-SRT-Or-RIST-Protocols) support
- Markdown, Pango and API text sources

## Portable?

Running OBS Studio in Portable Mode means all settings (Profiles and Scene Collections) are saved within the same directory tree as the OBS Studio executables, plugins, and configuration. You can copy the whole folder to another computer and use it.

[OBS Studio Portable is also a container image](https://github.com/ublue-os/obs-studio-portable) for [Distrobox](https://distrobox.it/), so you can run OBS Studio Portable on *any Linux distro*.

## Supported Software

The tarball of OBS Studio Portable includes a `manifest.txt` that describes precisely which versions of plugins and add-ons are included.

|                        | OBS Studio 29 | OBS Studio 30 |
| ---------------------- | ------------- | ------------- |
| Ubuntu 20.04 (Focal)   | 29.1.3 (Qt 5) | EOL           |
| Ubuntu 22.04 (Jammy)   | 29.1.3 (Qt 6) | 30.0.0-rc1    |
| Ubuntu 23.04 (Lunar)   | 29.1.3 (Qt 6) | 30.0.0-rc1    |
| Ubuntu 23.10 (Mantic)  | 29.1.3 (Qt 6) | 30.0.0-rc1    |
| Plugins                | 52            | 50            |

# Install

You can safely install these OBS Studio Portable builds alongside [`.deb`](https://launchpad.net/~obsproject/+archive/ubuntu/obs-studio), [Flatpak](https://flathub.org/apps/com.obsproject.Studio), or [Snap](https://snapcraft.io/obs-studio) installs of OBS Studio.

## Ubuntu

The installation process is simple:

- **[Download the tarball (and sha256 hash) of OBS Studio Portable](https://github.com/wimpysworld/obs-studio-portable/releases)** for the version of Ubuntu you're running.
  - **Builds are specific to an Ubuntu release!**
- Extract the tarball somewhere.
- Run `obs-dependencies`, included in the tarball, to make sure the runtime requirements for OBS Studio are satisfied.
- Run `obs-portable` to launch OBS Studio.
  - **You must use the `obs-portable` launcher** to ensure OBS Studio finds all the associated libraries and add-ons.

```bash
wget "https://github.com/wimpysworld/obs-studio-portable/releases/download/r23287/obs-portable-29.1.3-r23287-ubuntu-$(lsb_release -rs).tar.bz2"
wget "https://github.com/wimpysworld/obs-studio-portable/releases/download/r23287/obs-portable-29.1.3-r23287-ubuntu-$(lsb_release -rs).tar.bz2.sha256"
sha256sum -c obs-portable-29.1.3-r23287-ubuntu-$(lsb_release -rs).tar.bz2.sha256
tar xvf obs-portable-29.1.3-r23287-ubuntu-$(lsb_release -rs).tar.bz2
cd obs-portable-29.1.3-r23287-ubuntu-$(lsb_release -rs)
sudo ./obs-dependencies
./obs-portable
```
### Upgrades

The upgrade process is the same as an install, and you can copy the `config` folder from your old OBS Studio Portable directory to the new one.
If anything doesn't work correctly when you start the new OBS Studio, continue using the previous OBS Studio Portable instance.

## Distrobox (*any Linux*)

You can use [Distrobox](https://distrobox.it/) to run OBS Studio Portable on *any Linux 🐧 distro*.
The container image for OBS Studio Portable is maintained under the umbrella of the [Universal Blue](https://universal-blue.org/) project.

- **[OBS Studio Portable for Linux](https://github.com/ublue-os/obs-studio-portable)**

**The portable nature of OBS Studio Portable is redefined when using Distrobox.**
- *"portable"* now means you can run OBS Studio Portable on any Linux distro, not just Ubuntu.
- The OBS Studio configuration is exposed in your home directory on the host via the `~/.config/obs-portable` directory.
- Launching multiple instances of OBS Studio Portable containers is not recommended as the configuration location is shared.

**Running a single instance of OBS Studio Portable works great!** I am currently using OBS Studio Portable this way on NixOS ❄️

1. Install Distrobox (*1.4.2.1 or newer*) and Podman (*recommended*) or Docker.
2. Create a Distrobox container for OBS Studio Portable.

```bash
distrobox create --image ghcr.io/ublue-os/obs-studio-portable:latest --name obs --pull
```
### NVIDIA support

The appropriate NVIDIA libraries on the host should be automatically be linked inside the container 🪄
However, the capability for Distrobox to automatically connect NVIDIA libraries was added in Distrobox 1.5.0, and is also not supported on all distros; NixOS for example.

Therefore, if your are running an older version of Distrobox or the NVIDIA drivers are not automatically linked inside the container you can install them as follows:
  - Change the version number (***535** in the example below*) to match the version of the NVIDIA drivers you have installed on the host.

#### NVIDIA complete driver stack

Required if the display is rendered by an NVIDIA GPU.

```bash
distrobox create --image ghcr.io/ublue-os/obs-studio-portable:latest --name obs --pull --additional-packages nvidia-driver-535
```

#### NVIDIA compute only

Suitable for multi-GPU systems where the NVIDIA GPU is not rendering the display and only being used for compute.

```bash
distrobox create --image ghcr.io/ublue-os/obs-studio-portable:latest --name obs --pull --additional-packages libnvidia-encode-535 nvidia-headless-no-dkms-535

3. Run the initial setup.

```bash
distrobox enter --name obs -- true
```

4. From now on, launch OBS Studio Portable using the `obs-portable` launcher.

```bash
distrobox enter --name obs -- /opt/obs-portable/obs-portable
```

If the OBS Studio Portable container cannot connect to the host X11 server, add [`xhost +si:localuser:$USER`](https://github.com/89luca89/distrobox/blob/main/docs/compatibility.md#compatibility-notes) to `~/.distroboxrc`.

### Multiple OBS Studio Portable instances in Distrobox

Should you require multiple instances of OBS Studio, each with its own configuration, follow the steps above to get OBS Studio Portable running in Distrobox.
Then, extract the OBS Studio tarball into a different directory in your home directory on the host.
For example:

```bash
mkdir ~/OBS-Studio-again
cd ~/OBS-Studio-again
wget "https://github.com/wimpysworld/obs-studio-portable/releases/download/r23287/obs-portable-29.1.3-r23287-ubuntu-$(lsb_release -rs).tar.bz2"
tar xvf obs-portable-29.1.3-r23287-ubuntu-$(lsb_release -rs).tar.bz2
cd obs-portable-29.1.3-r23287-ubuntu-$(lsb_release -rs)
```

To launch the second instance of OBS Studio Portable in Distrobox, run the following command:

```bash
distrobox-enter --name obs -- ~/OBS-Studio-again/obs-portable
```

# Why does this project exist?

If any of the following are true for you, you might find these builds of OBS Studio useful.

- **I want a version of OBS Studio for Ubuntu that has all the features enabled; *by default***
  - I use lots of 3rd party OBS Studio plugins in my stream configuration.
- **I stream from two different locations using multiple computers**
  - [Syncthing](https://syncthing.net/) syncs my streaming configuration between sites. I'd also like to include OBS Studio itself.
- **I make changes to my OBS Studio configuration from various computers**
  - Keeping these changes in sync manually can be cumbersome.
- **I stream to multiple channels**
  - Discrete OBS Studio instances are easier to work with than switching between dozens of Profile and Scene Collection combinations.
- **I don't want to deal with flag day releases of new software**
  - New software is terrific, but I want to control when and how I upgrade each streaming configuration instance.
- **My stream integrations are not (currently) compatible with packages of OBS Studio that use confinement**
  - I have some funky stream integration;, and will likely create more. I don't want to limit my creative options.
- **I sometimes stream OBS Studio how-tos and examples**
  - Running demo instances of OBS Studio with isolated configurations is excellent for this.
- **I want a stable OBS setup and an in-development OBS setup**
  - When developing new features for my stream, I can freely experiment with new versions of OBS Studio and its plugins without fear of disrupting my stable setup.
- **I sometimes need old versions of OBS Studio**
  - I have some streaming projects that are archived and don't need upgrading. But I do want to reference them from time to time.

# Batteries included 🔋

I'm incredibly thankful to the OBS Studio developers and developers of the growing list of excellent plugins.
These Portable builds of OBS Studio for Ubuntu celebrates the best of what's available. Thank you! 🙇

Here are the 3rd party plugins that come bundled with OBS Studio Portable for Ubuntu:

## Audio 🔉

- **[Audio Pan](https://github.com/norihiro/obs-audio-pan-filter)** plugin; control stereo pan of audio sources.
- **[Local Vocal](https://github.com/obs-ai/obs-localvocal)** plugin; local speech and text AI processing routines and  AI transcription.
- **[Mute Filter](https://github.com/norihiro/obs-mute-filter)** plugin; to mute audio from a source.
- **[PipeWire Audio Capture](https://github.com/dimtpap/obs-pipewire-audio-capture)** plugin; capture application audio from PipeWire.
- **[Scale to Sound](https://github.com/Qufyy/obs-scale-to-sound)** plugin; adds a filter which makes a source scale based on the audio levels of any audio source you choose
- **[Soundboard](https://github.com/cg2121/obs-soundboard)** plugin; adds a soundboard dock.
- **[Tuna](https://github.com/univrsal/tuna)** plugin; get song information from various sources.
- **[Waveform](https://github.com/phandasm/waveform)** plugin; audio spectral analysis.

## Automation 🎛

- **[Advanced Scene Switcher](https://github.com/WarmUpTill/SceneSwitcher)** plugin; an automated scene switcher.
- **[Directory Watch Media](https://github.com/exeldro/obs-dir-watch-media)** plugin; filter you can add to a media source to load the oldest or newest file in a directory.
- **[Dummy Source](https://github.com/norihiro/obs-command-source)** plugin; provides a dummy source to execute arbitrary commands when a scene is switched.
- **[Source Switcher](https://github.com/exeldro/obs-source-switcher)** plugin; to switch between a list of sources.
- **[Transition Table](https://github.com/exeldro/obs-transition-table)** plugin; customize scene transitions.
- **[Websockets](https://github.com/Palakis/obs-websocket)** plugin; remote-control OBS Studio through WebSockets.

## Effects ✨

- **[3D Effect](https://github.com/exeldro/obs-3d-effect)** plugin; 3D effect filter.
- **[Background Removal](https://github.com/obs-ai/obs-backgroundremoval)** plugin; portrait background removal, virtual green-screen and low-light enhancement
- **[Browser Transition](https://github.com/exeldro/obs-browser-transition)** plugin; show a browser source during scene transition.
- **[Composite Blur](https://github.com/FiniteSingularity/obs-composite-blur)** plugin; comprehensive blur plugin that provides several different blur algorithms, and proper compositing.
- **[DVD Screensaver](https://github.com/univrsal/dvds3)** plugin; a DVD screen saver source type.
- **[Downstream Keyer](https://github.com/exeldro/obs-downstream-keyer)** plugin; add a Downstream Keyer dock.
- **[Dynamic Delay](https://github.com/exeldro/obs-dynamic-delay)** plugin; filter for dynamic delaying a video source.
- **[Face Tracker](https://github.com/norihiro/obs-face-tracker)** plugin; face tracking plugin
- **[Freeze Filter](https://github.com/exeldro/obs-freeze-filter)** plugin; freeze a source using a filter.
- **[Gradient](https://github.com/exeldro/obs-gradient-source)** plugin; adding gradients as a source.
- **[Move Transition](https://github.com/exeldro/obs-move-transition)** plugin; move source to a new position during a scene transition.
- **[Multi Source Effect](https://github.com/norihiro/obs-multisource-effect)** plugin; provides a custom effect to render multiple sources.
- **[Pixel Art](https://github.com/dspstanky/pixel-art)** plugin; create retro-inspired pixel art visuals.
- **[Recursion Effect](https://github.com/exeldro/obs-recursion-effect)** plugin; recursion effect filter.
- **[Replay Source](https://github.com/exeldro/obs-replay-source)** plugin; slow motion replay async sources from memory.
- **[RGB Levels](https://github.com/wimpysworld/obs-rgb-levels-filter)** plugin; simple filter to adjust RGB levels.
- **[Scene as Transition](https://github.com/andilippi/obs-scene-as-transition)** plugin; use scenes as transitions.
- **[Shader Filter](https://github.com/exeldro/obs-shaderfilter)** plugin; for applying an arbitrary shader to a source.
- **[Stroke Glow Shadow](https://github.com/FiniteSingularity/obs-stroke-glow-shadow)** plugin; provide efficient Stroke, Glow, and Shadow effects on masked sources.
- **[Time Shift](https://github.com/exeldro/obs-time-shift)** plugin;  time shift a source using a filter.
- **[Time Warp Scan](https://github.com/exeldro/obs-time-warp-scan)** plugin; a time warp scan filter.
- **[Vintage Filter](https://github.com/cg2121/obs-vintage-filter)** plugin; a filter to make source black & white or sepia.

## Encoding & Output 🎞

- **[Game Capture](https://github.com/nowrep/obs-vkcapture)** plugin; Vulkan/OpenGL game capture.
- **[GStreamer](https://github.com/fzwoch/obs-gstreamer)** plugin; feed GStreamer launch pipelines into OBS Studio.
- **[NDI](https://github.com/obs-ndi/obs-ndi)** plugin; Network A/V in OBS Studio with NewTek's NDI technology.
- **[Source Record](https://github.com/exeldro/obs-source-record)** plugin; make sources available to record via a filter.
- **[Teleport](https://github.com/fzwoch/obs-teleport)** plugin; open NDI-like replacement. (*not NDI compatible*)
- **[VA-API](https://github.com/exeldro/obs-transition-table)** plugin; GStreamer-based VA-API encoder implementation.
- **[Vertical Canvas](https://github.com/Aitum/obs-vertical-canvas)** plugin; make content for TikTok, YouTube Shorts, Instagram Live, and more without the fuss.

## Tools 🛠

- **[Scene Notes Dock](https://github.com/exeldro/obs-scene-notes-dock)** plugin; create a Dock for showing and editing notes for the currently active scene.
- **[Source Clone](https://github.com/exeldro/obs-source-clone)** plugin; add source cloning
- **[Source Copy](https://github.com/exeldro/obs-source-copy)** plugin; adds copy-and-paste options to the tools menu.
- **[Source Dock](https://github.com/exeldro/obs-source-dock)** plugin; adds browser sources as custom docks.

## Text 📝

- **[Markdown](https://github.com/exeldro/obs-markdown)** plugin; add Markdown sources
- **[Text PThread](https://github.com/norihiro/obs-text-pthread)** plugin; Rich text source plugin with many advanced features, including multi-language support, emoji support, vertical rendering and RTL support.
- **[URL Source](https://github.com/obs-ai/obs-urlsource)** plugin; fetch data from a URL (API), parse and display live update in scene.

### Removed 🗑️

These plugins were previously bundled with OBS Studio, but have since been removed.

- **[Asynchronous Source Duplication](https://github.com/norihiro/obs-async-source-duplication)** - The Source Clone plugin does the same thing.
- **[Color Monitor](https://github.com/norihiro/obs-color-monitor)** - name collisions with other plugins.
- **[NvFBC](https://gitlab.com/fzwoch/obs-nvfbc)** - no longer functional since OBS Studio 28 due to the removal of GLX.
  - Requires [NvFBC patches for Nvidia [drivers](https://github.com/keylase/nvidia-patch) for consumer-grade GPUs.
- **[RTSP Server](https://github.com/iamscottxu/obs-rtspserver/)** - introduced a large number of memory leaks.
- **[Scene Collection Manager](https://github.com/exeldro/obs-scene-collection-manager)** - can silently revert configurations to an older version.
- **[StreamFX](https://github.com/Xaymar/obs-StreamFX)** - dropped from OBS 30 onward. Incompatible with Vertical Plugin, 0.12.0b366 onwards forcibly include pointless UI elements and component inclusion is no longer configurable. StreamFX features are now provided via superior plugins and StreamFX development has fallen way behind OBS Studio release cadence.

### To consider 🤔

Here are some additional plugins that look useful that I might add in the future:

- <https://git.vrsal.xyz/alex/Durchblick>
- <https://github.com/ashmanix/obs-plugin-countdown>
- <https://github.com/obs-ai/obs-cleanstream>
- <https://github.com/LiveSplit/obs-livesplit-one>
- <https://github.com/norihiro/obs-async-audio-filter>
- <https://github.com/norihiro/obs-source-record-async>
- <https://github.com/norihiro/obs-output-filter>
- <https://github.com/norihiro/obs-main-view-source>
- <https://github.com/norihiro/obs-vnc>
- <https://github.com/univrsal/input-overlay>

#### gPhoto

There isn't a definitive gPhoto plugin for OBS Studio so I'm reluctant to include it. Here's what I know:

- [Original obs-gphoto 0.3.0](https://github.com/Atterratio/obs-gphoto) - unmaintained and doesn't build against current OBS.
  - [Forked obs-gphoto 0.4.0](https://github.com/adlerweb/obs-gphoto) - unmaintained, updated for imagemagick7, I was using this with OBS 27.
  - [Forked obs-gphoto 0.3.0](https://github.com/mika314/obs-gphoto) - look like build system updates to work with OBS 28, but I haven't tested it.
  - [Forked obs-gphoto 0.3.0](https://github.com/christophehenry/obs-gphoto) - looks like build system and code updates to work with OBS 29, but I haven't tested it.

### Additional plugins

If the builds of OBS Studio offered here don't include a plugin that you use, you can download a pre-compiled version and add it to the portable folder:

- Put any `.so` files in `obs-plugins/64bit`
- Put any data files associated with the plugin in `data/obs-plugins/<plugin name>/`

## OBS Virtual Camera

OBS Studio Virtual Camera support is integrated. The `Start Virtual Camera` button is in the Controls pane below `Start Recording`. Here's how to install and configure `v4l2loopback`, which OBS uses:

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

Each build is compiled in a freshly provisioned systemd container. The somewhat hastily thrown-together *"build scripts"* are included in this repository.

The `build-*.sh` scripts are wrappers to help automate things, with [`build-auto.sh`](./build-auto.sh) being the main entry point.

The actual build script, [`obs-build.sh`](builder/obs-build.sh), gets injected into the new container and is responsible for actually building OBS Studio. Perhaps it might also serve as a reference for users of other Linux distributions who want to create their portable builds of OBS Studio.

## Release numbers

An OBS Studio Portable for Linux release number will be something like r23287, and the filename will indicate the version of OBS Studio and which Ubuntu release it is for:

```text
                     +-- OBS Portable for Ubuntu revision
                     |
                     v
obs-portable-29.1.3-r23287-ubuntu-22.04.tar.bz2
              ^                    ^
              |                    |
              +-- OBS version      +-- Supported Ubuntu release
```

The purpose of the release number is to indicate a change to the composition of the portable release, most likely due to adding/updating the bundled 3rd party plugins.

# References

- https://obsproject.com/wiki/Build-Instructions-For-Linux
- https://github.com/snapcrafters/obs-studio
- https://launchpad.net/~obsproject
