(function () {
  function ready(fn) {
    if (document.readyState !== "loading") fn();
    else document.addEventListener("DOMContentLoaded", fn);
  }

  var ACTIVE_TAB_CLASSES = [ "bg-gray-100", "text-gray-900" ];
  var INACTIVE_TAB_CLASSES = [ "text-gray-500", "hover:text-gray-900" ];
  var VIEWPORT_WIDTHS = { mobile: "375px", desktop: "100%" };

  ready(function () {
    var form = document.getElementById("campaign-form");
    var frame = document.getElementById("campaign-preview-frame");
    var closeLink = document.getElementById("campaign-edit-close");
    var viewportTabs = document.querySelectorAll(".preview-viewport-tab");
    if (!frame) return;

    if (form && frame.dataset.previewUrl) {
      var timer = null;
      var dirty = false;
      // Trix loads its initial document synchronously while the editor connects, firing a
      // trix-change before "trix-initialize" (deferred to the next animation frame) ever fires.
      // Ignore trix-change until trix-initialize has fired so that mounting the editor with
      // existing body_html content isn't mistaken for a user edit.
      var trixReady = false;

      form.addEventListener("trix-initialize", function () { trixReady = true; });

      var schedule = function () {
        clearTimeout(timer);
        timer = setTimeout(refresh, 600);
      };

      var refresh = function () {
        var formData = new FormData(form);
        // form_with's hidden _method=patch field would otherwise make Rails' method-override
        // middleware treat this as a PATCH to /campaigns/:id, which has no /preview route.
        formData.delete("_method");

        fetch(frame.dataset.previewUrl, { method: "POST", body: formData })
          .then(function (response) { return response.text(); })
          .then(function (html) { frame.srcdoc = html; });
      };

      var markDirty = function () { dirty = true; };
      var markDirtyFromTrix = function () { if (trixReady) markDirty(); };
      var scheduleFromTrix = function () { if (trixReady) schedule(); };

      form.addEventListener("input", markDirty);
      form.addEventListener("change", markDirty);
      form.addEventListener("trix-change", markDirtyFromTrix);
      form.addEventListener("input", schedule);
      form.addEventListener("change", schedule);
      form.addEventListener("trix-change", scheduleFromTrix);
      form.addEventListener("submit", function () { dirty = false; });

      window.addEventListener("beforeunload", function (event) {
        if (!dirty) return;
        event.preventDefault();
        event.returnValue = "";
      });

      if (closeLink) {
        closeLink.addEventListener("click", function (event) {
          if (!dirty) return;
          event.preventDefault();

          if (window.confirm("You have unsaved changes. Save them before closing?")) {
            form.requestSubmit();
          } else {
            window.location.href = closeLink.href;
          }
        });
      }
    }

    function setViewport(viewport) {
      frame.style.width = VIEWPORT_WIDTHS[viewport] || VIEWPORT_WIDTHS.desktop;

      viewportTabs.forEach(function (tab) {
        var active = tab.dataset.previewViewport === viewport;
        tab.classList.toggle(ACTIVE_TAB_CLASSES[0], active);
        tab.classList.toggle(ACTIVE_TAB_CLASSES[1], active);
        INACTIVE_TAB_CLASSES.forEach(function (cls) { tab.classList.toggle(cls, !active); });
        tab.setAttribute("aria-pressed", active);
      });
    }

    viewportTabs.forEach(function (tab) {
      tab.addEventListener("click", function () { setViewport(tab.dataset.previewViewport); });
    });

    if (viewportTabs.length) setViewport("desktop");
  });
})();
