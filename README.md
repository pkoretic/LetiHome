# LetiHome

[![License MIT](https://cdn.rawgit.com/pkoretic/letihome/badges/license.svg)](https://github.com/pkoretic/letihome/blob/master/LICENSE)
[![Language (Qt)](https://cdn.rawgit.com/pkoretic/letihome/badges/qt.svg)](https://www.qt.io)

Android launcher optimized for the big screen. Targets embedded and TV/STB
devices. It is intended to be very lightweight and simple.

Android TV OS / Google Play OS<br/>
<p align="center">
    <img src="https://raw.githubusercontent.com/pkoretic/LetiHome/badges/tvscreenshot.png" width="30%" />
    &nbsp; &nbsp; &nbsp; &nbsp;
    <img src="https://raw.githubusercontent.com/pkoretic/LetiHome/badges/tvscreenshot-about.png" width="30%" />
    &nbsp; &nbsp; &nbsp; &nbsp;
    <img src="https://raw.githubusercontent.com/pkoretic/LetiHome/badges/tvscreenshot-appinfo.png" width="30%" />
</p>

Android Box / Tablet OS<br/>
<p align="center">
<img src="https://raw.githubusercontent.com/pkoretic/LetiHome/refs/heads/badges/nontvscreenshot.png" width=300 />
</p>

Google Play
----------------

[![Get it on Google Play](https://developer.android.com/images/brand/en_generic_rgb_wo_60.png)](https://play.google.com/store/apps/details?id=hr.envizia.letihome)

or download from [Releases](../../releases).

## Usage

Keys `Enter/Return/OK` or mouse (Left click) can be used to open applications.<br/>
`Menu/Back` or mouse right click will open Application Info.<br/>
Opening LetiHome (Pressing Enter/Return/OK) will open About page with System Settings option.

## Set LetiHome Launcher as default launcher on Android TV / Google TV

Note: on Android boxes that run regular Android OS (usually as "tablet" device)
and not Android TV OS you can set Home launcher as usual with "Home" button
press after installation and don't need methods below.

### Method 1: remap the Home button
In case you have support for accessibility you can use [Button
Mapper](https://play.google.com/store/apps/details?id=flar2.homebutton) to
remap the Home button of the remote to launch LetiHome.

### Method 2: disable the default launcher

The following commands have been tested on Chromecast with Google TV and
Philips Android TV. This may be different on other devices.

Once the default launcher is disabled, press the Home button on the remote, and
you'll be prompted by the system to choose which app to set as default.

#### Disable default launcher
```shell
# Disable com.google.android.apps.tv.launcherx which is the default launcher on CCwGTV
$ adb shell pm disable-user --user 0 com.google.android.apps.tv.launcherx
# com.google.android.tungsten.setupwraith will then be used as a 'fallback' and will automatically
# re-enable the default launcher, so disable it as well
$ adb shell pm disable-user --user 0 com.google.android.tungsten.setupwraith
```

#### Re-enable default launcher
In case when you want to delete LetiHome and restore original behavior.
```shell
$ adb shell pm enable com.google.android.apps.tv.launcherx
$ adb shell pm enable com.google.android.tungsten.setupwraith
```

#### Known issues
On Chromecast with Google TV (maybe others), the "YouTube" remote button will
stop working if the default launcher is disabled. As a workaround, you can use
[Button Mapper](https://play.google.com/store/apps/details?id=flar2.homebutton)
to remap it correctly.

## Building

It is written using [Qt/QML](https://www.qt.io) as regular Qt android
application.

Open `CmakeFiles.txt` in QtCreator and follow
https://doc.qt.io/qt-6/android.html.

