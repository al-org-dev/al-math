require 'minitest/autorun'
require 'liquid'

require_relative '../lib/al_math'

class AlMathTagsTest < Minitest::Test
  Site = Struct.new(:config)
  FakeSite = Struct.new(:static_files)

  def render_styles(config:, page:)
    template = Liquid::Template.parse('{% al_math_styles %}')
    template.render({}, registers: { site: Site.new(config), page: page })
  end

  def render_scripts(config:, page:)
    template = Liquid::Template.parse('{% al_math_scripts %}')
    template.render({}, registers: { site: Site.new(config), page: page })
  end

  def third_party_libraries
    {
      'mathjax' => { 'url' => { 'js' => 'https://cdn.example/mathjax.js' }, 'integrity' => { 'js' => 'sha-mathjax' } },
      'pseudocode' => { 'url' => { 'js' => 'https://cdn.example/pseudocode.js' }, 'integrity' => { 'js' => 'sha-pseudocode' } },
      'polyfill' => { 'url' => { 'js' => 'https://cdn.example/polyfill.js' } }
    }
  end

  def test_renders_mathjax_and_pseudocode_branch
    output = render_scripts(
      config: {
        'baseurl' => '/base',
        'enable_math' => true,
        'third_party_libraries' => third_party_libraries
      },
      page: { 'pseudocode' => true }
    )

    assert_includes output, 'mathjax.js'
    assert_includes output, '/base/assets/al_math/js/pseudocode-setup.js'
    assert_includes output, 'pseudocode.js'
    refute_includes output, '/base/assets/al_math/js/mathjax-setup.js'
  end

  def test_renders_mathjax_setup_when_pseudocode_disabled
    output = render_scripts(
      config: {
        'baseurl' => '/base',
        'enable_math' => true,
        'third_party_libraries' => third_party_libraries
      },
      page: {}
    )

    assert_includes output, '/base/assets/al_math/js/mathjax-setup.js'
    assert_includes output, 'polyfill.js'
  end

  def test_renders_tikz_assets_when_enabled_on_page
    styles = render_styles(
      config: { 'baseurl' => '/base' },
      page: { 'tikzjax' => true }
    )
    scripts = render_scripts(
      config: { 'baseurl' => '/base', 'enable_math' => false, 'third_party_libraries' => third_party_libraries },
      page: { 'tikzjax' => true }
    )

    assert_includes styles, '/base/assets/al_math/css/tikzjax.min.css'
    assert_includes scripts, '/base/assets/al_math/js/tikzjax.min.js'
  end

  def test_assets_generator_registers_math_assets
    site = FakeSite.new([])

    AlMath::AssetsGenerator.new.generate(site)

    names = site.static_files.map(&:name)
    assert_includes names, 'mathjax-setup.js'
    assert_includes names, 'pseudocode-setup.js'
    assert_includes names, 'tikzjax.min.js'
    assert_includes names, 'tikzjax.min.css'
  end
end
