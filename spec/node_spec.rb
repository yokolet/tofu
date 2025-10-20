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
  it "returns an array of attributes" do
    node_set = html.xpath('//a')
    expect(node_set.size).to eq(1)
    attributes = node_set.first.attributes
    attributes = attributes.to_h.to_a.sort
    expect([["class", "bar"], ["href", "foo"]]).to eq(attributes)
  end

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

  it "sets an attribute" do
    node_set = html.css('div')
    expect(node_set.size).to eq(1)
    element = node_set[0]
    element.attributes[:href] = "http://nokogiri.org/"
    expect(element.to_s).to match(/nokogiri.org/)
  end

  it "gets a namespaced attribute" do
    input = '<i foo:bar="baz"></i>'
    doc = Gammo.new(input).parse
    node = doc.css('i').first
    expect(node.attributes["foo:bar"]).to eq("baz")
  end
end