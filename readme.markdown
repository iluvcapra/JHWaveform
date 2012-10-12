# JHWaveform

JHWaveform is An NSView subclass that draws a waveform overview. The view provides an optional ruler, grid and allows selection. JHWaveformView is able to graph any float* array, and a subclass, JHAudioPreviewView, attaches to an AVPlayer object and renders an overview of that player's asset, allows you to seek on the asset through the view, and renders the playhead position on the view.

## JHWaveformView

The class JHWaveformView creates a simple view of an array of floats, with the value 0.0 at the centerline and +1.0/-1.0 at the edges.  The class also handles drawing of the ruler, gridlines, and selection box.  The selection box is meant to approximate the behavior of the Pro Tools selector tool -- a region may be hilighted, and the selection may be extended or trimmed by holding down the SHIFT key.  All of the colors used by the waveform view are settable and live-updateable through a set of properties, see the header or the Demo app for a complete description.

You draw a waveform with JHWaveformView by giving it an array of float values, thus:
    
<pre>

IBOutlet JHWaveformView *view;

NSUInteger myDataLength = GetMyDataLength();
float *myData = CopyMyData();

[view setWaveform:myData length:myDataLength];

free(myData);

</pre>

JHWaveformView does not retain or copy the samples you give it, nor does it require the client to do so. Once -setWaveform:length: returns, you may dispose of the float array.

You can observe the current selection of the view by adding an observer to the @selectedSampleRange property.  This gives the presently selected area as an NSRange of the samples.

The drawing of the waveform is optimized for the case of very long arrays (as in the case of an hour-long 96k wave file) by coalescing windows of samples into their maximum/minimum values.  For an array with less than a certain number of samples (presently 2000), the view will stroke a path for each sample literally; for arrays greater than that, the floats will be coalesced.

## JHAudioPreviewView

JHAudioPreviewView cooperates with an AVPlayer in order to render its audio content as a waveform, and give visual feedback on the player's seek position.  It draws a playhead over the waveform, and observes the player to keep the playhead in sync with the player's current location.

<pre>

IBOutlet JHAudioPreviewView *view;

AVPlayer *aPlayer = [AVPlayer playerWithURL:[self myMediaURL]];

view.player = aPlayer;

</pre>

Once you set the player, the view begins to read the player's currentPlayerItem and asset in order to render the overview.  This can be a long-running operations for many kinds of assets, so JHAudioPreviewView will read the asset in the background.  You can observe the boolean property @isReadingOverview to find out if the view is currently in the process of reading an asset; this will switch from YES to NO as the view is ready to display the waveform.