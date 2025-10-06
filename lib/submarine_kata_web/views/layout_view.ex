defmodule SubmarineKataWeb.LayoutView do
  use SubmarineKataWeb, :view
  import Phoenix.Component
  import Phoenix.Controller, only: [get_csrf_token: 0]

  def render("root.html", assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" data-theme="light">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={get_csrf_token()} />
        <.live_title suffix=" · Submarine Kata">
          {assigns[:page_title] || "Submarine Kata"}
        </.live_title>
        <link phx-track-static rel="stylesheet" href="/assets/app.css" />
        <script defer phx-track-static src="/assets/phoenix.min.js"></script>
        <script defer phx-track-static src="/assets/phoenix_live_view.min.js"></script>
        <script>
          // Only initialize once
          if (!window.liveSocketInitialized) {
            window.liveSocketInitialized = true;

            document.addEventListener('DOMContentLoaded', function() {
              // Wait a bit for Phoenix libraries to load, then initialize
              setTimeout(function() {
                console.log("Initializing LiveView...");

                // Get CSRF token
                let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

                if (typeof Phoenix === 'undefined' || typeof Phoenix.Socket === 'undefined' || typeof LiveView === 'undefined' || typeof LiveView.LiveSocket === 'undefined') {
                  console.error("Phoenix libraries not loaded!");
                  return;
                }

                // Create LiveSocket connection
                let liveSocket = new LiveView.LiveSocket("/live", Phoenix.Socket, {
                  longPollFallbackMs: 2500,
                  params: {_csrf_token: csrfToken}
                })

                // Show progress bar on page navigation
                liveSocket.enableDebug()

                // Connect if there are any LiveViews on the page
                liveSocket.connect()

                // Expose liveSocket on window for web console debug logs and latency simulation:
                window.liveSocket = liveSocket
                console.log("LiveView setup complete!");

              }, 100); // Wait 100ms for Phoenix libraries to load
            });
          }
        </script>
      </head>
      <body>
        <div class="min-h-screen bg-base-200">
          <nav class="navbar bg-primary text-primary-content">
            <div class="navbar-start">
              <a href="/" class="btn btn-ghost normal-case text-xl">Submarine Kata</a>
            </div>
            <div class="navbar-end">
              <div class="dropdown dropdown-end">
                <label tabindex="0" class="btn btn-ghost btn-circle">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h7" /></svg>
                </label>
                <ul tabindex="0" class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52">
                  <li><a href="/part2" class="text-gray-900 hover:text-blue-600 hover:bg-blue-50">Part 2: Aim-based Navigation</a></li>
                  <li><a href="/" class="text-gray-900 hover:text-blue-600 hover:bg-blue-50">Part 3: Map Reconstruction</a></li>
                </ul>
              </div>
            </div>
          </nav>

          <main class="container mx-auto px-4 py-8">
            {@inner_content}
          </main>

          <footer class="footer footer-center p-4 bg-base-300 text-base-content">
            <aside>
              <p>Submarine Kata - Phoenix LiveView Visualization</p>
            </aside>
          </footer>
        </div>
      </body>
    </html>
    """
  end
end
