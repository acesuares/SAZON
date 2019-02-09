class Document < ActiveRecord::Base
  include BaseUrlHelper
  attr_reader :per_page
  @per_page = 999
  attr_writer :inline_forms_attribute_list
  has_paper_trail

  belongs_to :document

  has_many :documents
  has_many :assignments
  has_many :images

  validates :name, presence: true
  validates :slug, presence: true,
                   uniqueness: true,
                   format: { with: Rails.configuration.slug_regex, message: "begint met een kleine letter en daarna kleine letters, underscore en cijfers" }

  default_scope { order :name }

  def _presentation
    name
  end

  def content_pdf_formatted
    # get rid of iframes
    html_doc = Nokogiri::HTML(content)
    html_doc.search('.//iframe').each do |iframe|
      new_node = html_doc.create_element "span"
      new_node.inner_html = "Video: #{iframe.attributes['src'].value.split('?').first rescue ''}"
      iframe.replace new_node
    end
    html_doc.at('body').inner_html rescue ''
  end

  def nice_number
    self.name.scan(/[.0-9]+/).first.gsub('0','')
  end

  def nice_begrippen_page_number
    (documents.last.nice_number.to_f + 0.1).round(1).to_s
  end

  def nice_isms_page_number
    (documents.last.nice_number.to_f + 0.2).round(1).to_s
  end


  def nice_title
    nice_number.length > 1 ? "#{nice_number} #{title}" : title
  end

  def clean_name
    slug
  end

  def parent
    self.document
  end

  def has_no_parent?
    self.parent.nil?
  end

  def children
    documents.where(which_menu: [1, 3]).each.map do |document|
      [document, document.children]
    end
  end

  def url
    build_url("view/#{slug}")
  end

  def root_and_children
    [Document.find(ROOT_ID), Document.find(ROOT_ID).children].flatten
  end

  def next
    root_and_children[root_and_children.index(self)+1] rescue nil
  end

  def previous
    position = (root_and_children.index(self) - 1) rescue -1
    position < 0 ? nil : root_and_children[position]
  end

  def module_and_children
    [self.this_module, self.this_module.children].flatten
  end

  def is_module_last_document?
    self.id == module_and_children.last.id
  end

  def is_root?
    self.id == ROOT_ID
  end

  def is_module?
    self.id == self.this_module.id
  end

  def this_module
    return Document.find(ROOT_ID) if self.is_root? || self.has_no_parent?
    parent.is_root? ? self : parent.this_module
  end

  def this_module_number
    this_module.slug.last.to_i.to_s
  end

  def this_chapter
    return Document.find(ROOT_ID) if self.is_module? || self.is_root? || self.has_no_parent?
    parent.is_module? ? self : parent.this_chapter
  end

  def left_background_class
    "left_bg_m#{this_module_number}"
  end

  def right_background_class
    "right_bg_m#{this_module_number}"
  end

  def module_begrips
    module_and_children.map {|d| d.begrips }.flatten.uniq.sort
  end

  def module_isms
    module_and_children.map {|d| d.isms }.flatten.uniq.sort
  end

  def module_with_begrips?
    module_and_children.detect {|d| d.begrips.count > 0 }
  end

  def module_with_isms?
    module_and_children.detect {|d| d.isms.count > 0 }
  end

  def module_any_begrip_or_ism?
    module_with_begrips? || module_with_isms?
  end

  def begrips
    begrips = []
    begrips << Begrip.exclude_isms.where(name: text_begrips)
    begrips << Begrip.exclude_isms.joins(:related_words).where(related_words: { name: text_begrips } )
    begrips.flatten.uniq.sort
  end

  def begrips_alphabetized
    begrips_alphabetized = {}
    self.begrips.each do |begrip|
      first_letter = begrip.name[0].downcase
      begrips_alphabetized[first_letter] = [] if begrips_alphabetized[first_letter].nil?
      begrips_alphabetized[first_letter] << begrip
    end
    begrips_alphabetized
  end

  def module_begrips_alphabetized
    module_begrips_alphabetized = {}
    self.module_begrips.each do |begrip|
      first_letter = begrip.name[0].downcase
      module_begrips_alphabetized[first_letter] = [] if module_begrips_alphabetized[first_letter].nil?
      module_begrips_alphabetized[first_letter] << begrip
    end
    module_begrips_alphabetized
  end

  def isms
    isms = []
    isms << Begrip.only_isms.where(name: text_begrips)
    isms << Begrip.only_isms.joins(:related_words).where(related_words: { name: text_begrips } )
    isms.flatten.uniq.sort
  end

  def isms_alphabetized
    isms_alphabetized = {}
    self.isms.each do |ism|
      first_letter = ism.name[0].downcase
      isms_alphabetized[first_letter] = [] if isms_alphabetized[first_letter].nil?
      isms_alphabetized[first_letter] << ism
    end
    isms_alphabetized
  end

  def module_isms_alphabetized
    module_isms_alphabetized = {}
    self.module_isms.each do |ism|
      first_letter = ism.name[0].downcase
      module_isms_alphabetized[first_letter] = [] if module_isms_alphabetized[first_letter].nil?
      module_isms_alphabetized[first_letter] << ism
    end
    module_isms_alphabetized
  end

  def text_begrips
    content = self.content.to_s + self.sidebar.to_s + images.all.map(&:description).join
    content.gsub!(/\/uploads\/ckeditor\/pictures\/([0-9]+)\/content_/,'/uploads/ckeditor/pictures/\1/content-')
    content.downcase.scan(/_.+?_/).map {|x|Nokogiri::HTML.parse(x.gsub('_','')).text}
  end

  def inline_forms_attribute_list
    @inline_forms_attribute_list ||= [
      [ :name , "name", :text_field ],
      [ :slug , "name", :text_field ],
      [ :document , "name", :dropdown ],
      [ :which_menu, '', :dropdown_with_values, WHICH_MENU],
      [ :css , "content", :text_area_without_ckeditor ],
      [ :header_content, '', :header ],
      [ :title , "title", :text_field ],
      [ :content , "content", :text_area ],
      [ :sidebar, '', :text_area ],
      [ :assignments, '', :associated ],
      [ :documents, '', :associated ],
      [ :header_masonry, '', :header ],
      [ :masonry_title_above, '', :dropdown_with_values, JA_NEE ],
      [ :masonry_text_above, '', :dropdown_with_values, JA_NEE ],
      [ :masonry_column_width, '', :text_field ],
      [ :masonry_gutter_width, '', :text_field ],
      [ :images, '', :associated ],
    ]
  end


  def <=>(other)
    self.last_name <=> other.last_name
  end


  def self.not_accessible_through_html?
    false
  end

  def self.order_by_clause
    nil
  end


end
