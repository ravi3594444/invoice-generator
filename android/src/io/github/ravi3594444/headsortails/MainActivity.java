package io.github.ravi3594444.headsortails;

import android.app.Activity;
import android.content.res.AssetManager;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Display;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.webkit.RenderProcessGoneDetail;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.util.Collections;

/**
 * Shows the coin toss page full screen. Every file the page needs ships inside the APK,
 * so the app works offline.
 */
public class MainActivity extends Activity {

    /** Requests to this host are answered from assets/, which gives the page a normal https origin. */
    private static final String HOST = "appassets.androidplatform.net";

    private WebView web;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        preferSixtyHertz();
        createPage();
    }

    /**
     * Asks for a steady 60 Hz at the current resolution. Most phones hold 60 fps with the 3D
     * scene, where 90 or 120 Hz would drop frames and stutter. (Phones before Android 6 are
     * 60 Hz anyway.)
     */
    private void preferSixtyHertz() {
        if (Build.VERSION.SDK_INT < 23) return;
        Display display = getWindowManager().getDefaultDisplay();
        Display.Mode current = display.getMode();
        for (Display.Mode mode : display.getSupportedModes()) {
            if (mode.getPhysicalWidth() == current.getPhysicalWidth()
                    && mode.getPhysicalHeight() == current.getPhysicalHeight()
                    && Math.abs(mode.getRefreshRate() - 60f) < 1f) {
                WindowManager.LayoutParams attrs = getWindow().getAttributes();
                attrs.preferredDisplayModeId = mode.getModeId();
                getWindow().setAttributes(attrs);
                return;
            }
        }
    }

    private void createPage() {
        web = new WebView(this);
        web.setBackgroundColor(Color.rgb(0x0B, 0x14, 0x17));
        web.setOverScrollMode(View.OVER_SCROLL_NEVER);
        web.setVerticalScrollBarEnabled(false);
        web.setHorizontalScrollBarEnabled(false);

        WebSettings settings = web.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setMediaPlaybackRequiresUserGesture(false);
        settings.setAllowFileAccess(false);
        settings.setAllowContentAccess(false);

        web.setWebViewClient(new AssetClient(getAssets(), this));
        setContentView(web);
        web.loadUrl("https://" + HOST + "/index.html");
    }

    /**
     * The page's renderer process was killed, usually to free memory while the app was in
     * the background. Put a fresh page in place of the dead one; the tally is saved.
     */
    void restartPage() {
        if (isFinishing()) return;
        destroyPage();
        createPage();
    }

    /** A WebView has to leave the view hierarchy before it is destroyed. */
    private void destroyPage() {
        if (web == null) return;
        ViewGroup parent = (ViewGroup) web.getParent();
        if (parent != null) parent.removeView(web);
        web.destroy();
        web = null;
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) {
            hideSystemBars();
        }
    }

    @SuppressWarnings("deprecation")
    private void hideSystemBars() {
        getWindow().getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                        | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                        | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_FULLSCREEN);
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (web != null) {
            web.onResume();
            web.resumeTimers();
        }
    }

    @Override
    protected void onPause() {
        if (web != null) {
            web.onPause();
            web.pauseTimers();
        }
        super.onPause();
    }

    @Override
    protected void onDestroy() {
        destroyPage();
        super.onDestroy();
    }

    /** Serves the page and its files from the APK. Nothing is fetched from the network. */
    private static final class AssetClient extends WebViewClient {
        private final AssetManager assets;
        private final MainActivity host;

        AssetClient(AssetManager assets, MainActivity host) {
            this.assets = assets;
            this.host = host;
        }

        @Override
        public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
            Uri url = request.getUrl();
            if (!HOST.equals(url.getHost())) {
                return notFound();
            }
            String path = url.getPath();
            if (path == null || path.length() <= 1) {
                path = "/index.html";
            }
            try {
                String mime = mimeType(path);
                String encoding = mime.startsWith("text/") || mime.endsWith("javascript") ? "utf-8" : null;
                return new WebResourceResponse(mime, encoding, assets.open(path.substring(1)));
            } catch (IOException e) {
                return notFound();
            }
        }

        @Override
        @SuppressWarnings("deprecation")
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            // The page never navigates anywhere else; ignore anything that tries to.
            return !HOST.equals(Uri.parse(url).getHost());
        }

        // Android 8.0+ calls this when the page's renderer dies. Without it the app is killed
        // or left frozen; with it, the page starts again. (Overrides an API 26 method, so no
        // @Override while compiling against API 23.)
        public boolean onRenderProcessGone(WebView view, RenderProcessGoneDetail detail) {
            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    host.restartPage();
                }
            });
            return true;
        }

        private static WebResourceResponse notFound() {
            return new WebResourceResponse("text/plain", "utf-8", 404, "Not Found",
                    Collections.<String, String>emptyMap(), new ByteArrayInputStream(new byte[0]));
        }

        private static String mimeType(String path) {
            if (path.endsWith(".html")) return "text/html";
            if (path.endsWith(".js")) return "application/javascript";
            if (path.endsWith(".css")) return "text/css";
            if (path.endsWith(".woff2")) return "font/woff2";
            if (path.endsWith(".png")) return "image/png";
            if (path.endsWith(".txt")) return "text/plain";
            return "application/octet-stream";
        }
    }
}
