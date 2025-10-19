RSpec.describe "Parser" do
  let(:html) {
    <<-eohtml
        <html>
          <head></head>
          <body>
            <div class='baz'><a href="foo" class="bar">first</a></div>
          </body>
        </html>
    eohtml
  }
  it "parses a simple example" do
    document = Gammo.new(html).parse
    elements = document.xpath('//a')
    expect(elements.size).to eq(1)
    attributes = elements.first.attributes
    expect(attributes['class']).to eq('bar')
    expect(attributes['href']).to eq('foo')
  end
end