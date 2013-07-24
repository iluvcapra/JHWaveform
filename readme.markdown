# JHWaveform

`JHWaveform` is An `NSView` subclass that draws a waveform overview. The view provides an optional ruler, grid and allows selection. `JHWaveformView` is able to graph any `float*` array, and a subclass, `JHAudioPreviewView`, attaches to an `AVPlayer` object and renders an overview of that player's asset, allows you to seek on the asset through the view, and renders the playhead position on the view.

To build JHWaveform, you must have aubio installed, otherwise you will get a compiler error.

If you don't already have it, install homebrew, then

```$ brew install aubio```
