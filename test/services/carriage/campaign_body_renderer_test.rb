require "test_helper"

module Carriage
  class CampaignBodyRendererTest < ActiveSupport::TestCase
    test "constrains images to the body width and strips the auto-generated caption" do
      html = <<~HTML
        <div>
          <figure class="attachment attachment--preview attachment--png">
            <img src="/image.png" width="1024" height="768">
            <figcaption class="attachment__caption">
              <span class="attachment__name">photo.png</span>
              <span class="attachment__size">1.2 MB</span>
            </figcaption>
          </figure>
        </div>
      HTML

      result = Carriage::CampaignBodyRenderer.for_email(html)

      assert_includes result, 'style="max-width:100%;height:auto;"'
      assert_not_includes result, "width=\"1024\""
      assert_not_includes result, "attachment__caption"
    end

    test "styles a caption the user actually entered as light grey and centered" do
      html = <<~HTML
        <figure class="attachment attachment--preview attachment--png">
          <img src="/image.png" width="1024" height="768">
          <figcaption class="attachment__caption">Our new office</figcaption>
        </figure>
      HTML

      result = Carriage::CampaignBodyRenderer.for_email(html)

      assert_includes result, "Our new office"
      assert_includes result, "color:#999999"
      assert_includes result, "text-align:center"
    end
  end
end
