defmodule PhxLiveStorybook.Rendering.ComponentRendererTest do
  use ExUnit.Case, async: true

  alias PhxLiveStorybook.TreeStorybook
  import Phoenix.LiveViewTest

  setup_all do
    [
      component: TreeStorybook.load_story("/component") |> elem(1),
      live_component: TreeStorybook.load_story("/live_component") |> elem(1),
      afolder_component: TreeStorybook.load_story("/a_folder/component") |> elem(1),
      template_component: TreeStorybook.load_story("/templates/template_component") |> elem(1)
    ]
  end

  describe "render_variation/2" do
    test "it should return HEEX for each component/variation couple",
         %{component: component, live_component: live_component} do
      assert render_variation(component, :hello) |> rendered_to_string() ==
               "<span data-index=\"42\">component: hello</span>"

      assert render_variation(component, :world) |> rendered_to_string() ==
               "<span data-index=\"37\">component: world</span>"

      # I did not manage to assert against the HTML
      assert [%Phoenix.LiveView.Component{id: "live_component-hello"}] =
               render_variation(live_component, :hello).dynamic.([])

      assert [%Phoenix.LiveView.Component{id: "live_component-world"}] =
               render_variation(live_component, :world).dynamic.([])
    end

    test "it also works for a variation group", %{afolder_component: component} do
      assert render_variation(component, :group)
             |> rendered_to_string() ==
               String.trim("""
               <span data-index=\"42\">component: hello</span>
               <span data-index=\"37\">component: world</span>
               """)

      # I did not manage to assert against the HTML
      assert render_variation(component, :group)
    end

    test "it is working with a variation without any attributes", %{afolder_component: component} do
      assert render_variation(component, :no_attributes) |> rendered_to_string() ==
               "<span data-index=\"42\">component: </span>"
    end

    test "it is working with an inner_block requiring a let attribute" do
      {:ok, component} = TreeStorybook.load_story("/let/let_component")
      html = render_variation(component, :default) |> rendered_to_string()

      assert html =~ "**foo**"
      assert html =~ "**bar**"
      assert html =~ "**qix**"
    end

    test "it is working with an inner_block requiring a let attribute, in a live component" do
      {:ok, component} = TreeStorybook.load_story("/let/let_live_component")

      assert [%Phoenix.LiveView.Component{id: "let_live_component-default"}] =
               render_variation(component, :default).dynamic.([])
    end

    test "renders a variation with story template", %{template_component: component} do
      html =
        render_variation(component, :hello)
        |> rendered_to_string()
        |> Floki.parse_fragment!()

      assert html |> Floki.attribute("id") |> hd() == "hello"
      assert html |> Floki.find("span") |> length() == 1
    end

    test "renders a variation with its own template", %{template_component: component} do
      html =
        render_variation(component, :variation_template)
        |> rendered_to_string()
        |> Floki.parse_fragment!()

      assert html |> Floki.attribute("class") |> hd() == "variation-template"
      assert html |> Floki.find("span") |> length() == 1
    end

    test "renders a variation with which disables story's template", %{
      template_component: component
    } do
      html =
        render_variation(component, :no_template)
        |> rendered_to_string()
        |> Floki.parse_fragment!()

      assert html |> Floki.attribute("id") == []
      assert html |> Floki.find("span") |> length() == 1
    end

    test "renders a variation group with story template", %{template_component: component} do
      html =
        render_variation(component, :group)
        |> rendered_to_string()
        |> Floki.parse_fragment!()

      assert html |> Floki.attribute("id") |> length() == 2
      assert html |> Floki.attribute("id") |> Enum.at(0) == "group:one"
      assert html |> Floki.attribute("id") |> Enum.at(1) == "group:two"
      assert html |> Floki.find("span") |> length() == 2
    end

    test "renders a variation group with its own template", %{template_component: component} do
      html =
        render_variation(component, :group_template)
        |> rendered_to_string()
        |> Floki.parse_fragment!()

      assert html |> Floki.attribute("class") |> length() == 2
      assert html |> Floki.attribute("class") |> Enum.at(0) == "group-template"
      assert html |> Floki.attribute("class") |> Enum.at(1) == "group-template"
      assert html |> Floki.find("span") |> length() == 2
    end

    test "renders a variation group with a <.lsb-variation-group/> placeholder template", %{
      template_component: component
    } do
      html =
        render_variation(component, :group_template_single)
        |> rendered_to_string()
        |> Floki.parse_fragment!()

      assert html |> Floki.attribute("class") |> length() == 1
      assert html |> Floki.attribute("class") |> Enum.at(0) == "group-template"
      assert html |> Floki.find("span") |> length() == 2
    end

    test "renders a variation with a template, but no placeholder", %{
      template_component: component
    } do
      assert render_variation(component, :no_placeholder)
             |> rendered_to_string() == "<div></div>"
    end

    test "renders a variation group with a template, but no placeholder" do
      {:ok, component} = TreeStorybook.load_story("/templates/template_component")

      assert render_variation(component, :no_placeholder_group)
             |> rendered_to_string() == "<div></div>"
    end

    test "renders a variation with an invalid template placeholder will raise" do
      {:ok, component} = TreeStorybook.load_story("/templates/invalid_template_component")

      msg = "Cannot use <.lsb-variation-group/> placeholder in a variation template."

      assert_raise RuntimeError, msg, fn ->
        render_variation(component, :invalid_template_placeholder)
      end
    end

    test "renders a variation with a template passing extra attributes", %{
      template_component: component
    } do
      assert render_variation(component, :template_attributes)
             |> rendered_to_string() ==
               "<span>template_component: from_template / status: true</span>"
    end
  end

  defp render_variation(story, variation_id) do
    PhxLiveStorybook.Rendering.ComponentRenderer.render_variation(story, variation_id, %{})
  end
end