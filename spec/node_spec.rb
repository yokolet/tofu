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
    # verify css_path method later
    # memo: div[2] causes an error
    # also below causes an error
    # node = doc.xpath("//div[count(preceding-sibling::*)=1]")
  end

  <<-TEST
    assert_nil(@html.meta_encoding)
  TEST
  it "returns nil when encoding is not specified" do
    meta = meta_encoding(html)
    expect(meta).to be_nil
  end

  <<-TEST
    assert(desc = @html.at("a.bar").description)
    assert_equal("a", desc.name)
  TEST
  it "shows a description" do
    node = html.css("a.bar").first
    expect(node).not_to be_nil
    expect(node.tag).to eq("a")
  end

  <<-TEST
    assert(node = @html.at("a.bar").child)
    assert(list = node.ancestors(".baz"))
    assert_equal(1, list.length)
    assert_equal("div", list.first.name)
  TEST
  it "finds ancestors" do
    node = html.css("a.bar").first.first_child
    expect(node.parent).not_to be_nil
    list = ancestors(html, node, ".baz")
    expect(list.length).to eq(1)
    expect(list.first.tag).to eq("div")
  end

  <<-TEST
    assert(node = @html.at("a.bar"))
    assert(node.matches?("a.bar"))

    assert(node = @html.at("//a"))
    assert(node.matches?("//a"))
  TEST
  xit "finds matched node" do
    css = html.css("a.bar").first
    xpath = html.xpath("//a").first
    # needs the matches? method
  end

  <<-TEST
    node = @html.at("a")
    node.unlink

    assert_raises(RuntimeError) { node.add_previous_sibling(@html.at("div")) }
  TEST
  xit "unlinks matched node" do
    node = html.css("a").first
    # needs the unlink method
  end
end

def meta_encoding(document)
  if (meta = document.xpath("//meta[@charset]").first)
    meta.attributes[:charset]
  elsif (meta = meta_content_type(document).first)
    meta.attributes["content"][/charset\s*=\s*([\w-]+)/i, 1]
  end
end

def meta_content_type(document)
  # NameError: uninitialized constant Gammo::XPath::AST::AndExpr
  # document.xpath("//meta[@http-equiv and boolean(@content)]").find do |node|
  #   node["http-equiv"] =~ /\AContent-Type\z/i
  # end
  document.xpath("//meta[@http-equiv]") do |node|
    node.attributes["http-equiv"] =~ /\AContent-Type\z/i
  end
end

def ancestors(document, node, selector = nil)
  return Gammo::CSSSelector::NodeSet.new unless node.respond_to?(:parent)
  return Gammo::CSSSelector::NodeSet.new unless node.parent

  parents = [node.parent]

  while parents.last.respond_to?(:parent)
    break unless (ctx_parent = parents.last.parent)

    parents << ctx_parent
  end

  node_set = Gammo::CSSSelector::NodeSet.new
  search_result = selector ? html.css(selector) : nil
  parents.each do |parent|
    if selector
      node_set << parent if search_result.nodes.include?(parent)
    else
      node_set << parent
    end
  end
  node_set
end
