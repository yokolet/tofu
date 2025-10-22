RSpec.describe "TestNode" do
  let(:html) {
    Gammo.new(<<-eohtml).parse
        <html>
          <head></head>
          <body>
            <div class='baz'><a href="foo" class="bar">first</a></div>
          </body>
        </html>
    eohtml
  }

  <<-TEST
    assert_equal([["class", "bar"], ["href", "foo"]], @html.at("a").to_a.sort)
  TEST
  it "returns an array of attributes" do
    node_set = html.xpath('//a')
    expect(node_set.size).to eq(1)
    attributes = node_set.first.attributes
    attributes = attributes.to_h.to_a.sort
    expect([["class", "bar"], ["href", "foo"]]).to eq(attributes)
  end

  <<-TEST
    node = @html.at("div.baz")
    assert_equal("baz", node["class"])
    assert_equal("baz", node.attr("class"))
  TEST
  it "gets an attribute value using xpath" do
    xpath_node_set = html.xpath('//div[@class="baz"]')
    expect(xpath_node_set.size).to eq(1)
    node = xpath_node_set[0]
    expect(node.attributes[:class]).to eq("baz")
  end
  it "gets an attribute value using css selector" do
    css_node_set = html.css('div.baz')
    expect(css_node_set.size).to eq(1)
    node = css_node_set[0]
    expect(node.attributes[:class]).to eq("baz")
  end

  <<-TEST
    element = @html.at("div")
    assert_equal("baz", element.get_attribute("class"))
    assert_equal("baz", element["class"])
    element["href"] = "https://nokogiri.org/"
    assert_match(/nokogiri.org/, element.to_html)
  TEST
  it "sets an attribute" do
    node_set = html.css('div')
    expect(node_set.size).to eq(1)
    element = node_set[0]
    expect(element.attributes[:class]).to eq("baz")
    element.attributes[:href] = "http://nokogiri.org/"
    expect(element.to_s).to match(/nokogiri.org/)
  end

  <<-TEST
    html = '<i foo:bar="baz"></i>'
    doc = Nokogiri::HTML4(html)
    assert_equal("baz", (doc % "i")["foo:bar"])
  TEST
  it "gets a namespaced attribute" do
    input = '<i foo:bar="baz"></i>'
    doc = Gammo.new(input).parse
    node = doc.css('i').first
    expect(node.attributes["foo:bar"]).to eq("baz")
  end

  <<-TEST
    doc = Nokogiri::HTML4(File.read(HTML_FILE))
    ["#header", "small", "div[2]", "div.post", "body"].each do |css_sel|
      ele = doc.at(css_sel)
      assert_equal(ele, doc.at(ele.css_path), ele.css_path)
    end
  TEST
  it "does a round trip css path" do
    s = File.read(HTML_FILE)
    doc = Gammo.new(s).parse
    ["#header", "small", "div.post", "body"].each do |css_sel|
      node = doc.css(css_sel).first
      expect(node).to_not be_nil
    end
    # memo: div[2] causes an error
  end
end
