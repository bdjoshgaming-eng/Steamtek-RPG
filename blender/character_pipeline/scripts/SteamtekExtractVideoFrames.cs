using System;
using Windows.Foundation;
using Windows.Graphics.Imaging;
using Windows.Media.Editing;


public static class SteamtekMediaBridge
{
    private static MediaComposition activeComposition;

    public static void Initialize(MediaClip clip)
    {
        activeComposition = new MediaComposition();
        activeComposition.Clips.Add(clip);
    }

    public static IAsyncOperation<ImageStream> GetThumbnailAsync(
        double timeSeconds,
        int width,
        int height)
    {
        if (activeComposition == null)
        {
            throw new InvalidOperationException("Initialize must be called first.");
        }

        return activeComposition.GetThumbnailAsync(
            TimeSpan.FromSeconds(timeSeconds),
            width,
            height,
            VideoFramePrecision.NearestFrame);
    }
}
