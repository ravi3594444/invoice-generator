package android.webkit;

/**
 * Compile-time stand-in for the API 26 class, so MainActivity can handle a dead renderer
 * while building against API 23. It is never packaged; devices supply the real class.
 */
public abstract class RenderProcessGoneDetail {
    public abstract boolean didCrash();

    public abstract int rendererPriorityAtExit();
}
