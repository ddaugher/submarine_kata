// Phoenix LiveView JavaScript - Non-module version
// Phoenix and Phoenix LiveView are loaded globally via script tags

console.log("🚀 App.js loaded successfully!");
console.log("🔍 Document ready state:", document.readyState);

(function() {
  try {
    console.log("🔍 Checking for Phoenix libraries...");
    console.log("Socket available:", typeof Socket !== 'undefined');
    console.log("LiveSocket available:", typeof LiveSocket !== 'undefined');

    // Get CSRF token
    let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
    console.log("🔑 CSRF token found:", csrfToken ? "Yes" : "No");

    if (typeof Socket === 'undefined' || typeof LiveSocket === 'undefined') {
      console.error("❌ Phoenix libraries not loaded!");
      console.error("Available globals:", Object.keys(window).filter(k => k.includes('phoenix') || k.includes('Phoenix')));
      return;
    }

    // Create LiveSocket connection
    let liveSocket = new LiveSocket("/live", Socket, {
      longPollFallbackMs: 2500,
      params: {_csrf_token: csrfToken}
    })

    console.log("🔌 LiveSocket created successfully");

    // Show progress bar on page navigation
    liveSocket.enableDebug()

    // Connect if there are any LiveViews on the page
    liveSocket.connect()
    console.log("🚀 LiveSocket connection initiated");

    // Expose liveSocket on window for web console debug logs and latency simulation:
    // >> liveSocket.enableDebug() to enable debug logs
    // >> liveSocket.enableLatencySim(1000) to enable a latency simulator
    // >> liveSocket.disableLatencySim() to disable the latency simulator
    window.liveSocket = liveSocket
    console.log("✅ LiveView setup complete!");

  } catch (error) {
    console.error("❌ Error setting up LiveView:", error);
  }
})();
