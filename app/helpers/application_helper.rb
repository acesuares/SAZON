module ApplicationHelper
  def application_name
    'SAZON'
  end
  def application_title
    'SAZON'
  end

  def add_tooltips content = '', format = 'html', lightbox = false
    content = content.gsub(/\/uploads\/ckeditor\/pictures\/([0-9]+)\/content_/,'/uploads/ckeditor/pictures/\1/content-')
    content_begrips = content.scan(/_.+?_/).sort
    content_begrips.each do |needle|
      clean_needle = needle.gsub('_','')
      begrip = Begrip.find_by_name(Nokogiri::HTML.parse(clean_needle).text)
      if begrip.nil?
        content = content.gsub(needle, clean_needle)
      else
        if format == 'html'
          description = "#{begrip.name}<br /><br />#{begrip.description.gsub('"', "&quot;")}" + begrip.related_words_text('<br /><br />Gerelateerde begrippen: ')
          content = content.gsub(needle, "<span data-tooltip data-options=\"hover_delay: 10;\" aria-haspopup=\"true\" class=\"has-tip radius\" title=\"#{description}\">#{clean_needle}</span>")
        elsif format == 'pdf'
          content = content.gsub(needle, "<span class='pdf_begrip'>#{clean_needle}</span>")
        end
      end
    end
    if lightbox
      content += "<script>
        $(document).foundation('tooltip', 'reflow');
        $('.tooltip').css('z-index', '99999');
        </script>"
    end
    content.gsub(/\/uploads\/ckeditor\/pictures\/([0-9]+)\/content-/,'/uploads/ckeditor/pictures/\1/content_')
  end

  def show_alphabet(available_letters, current_letter, class_name)
    alphabet = ''
    ("a".."z").each do |letter|
      unless available_letters.include? letter
        alphabet += "<span class='alphabet_disabled'>#{letter}<span> "
      else
        alphabet_class = "alphabet_link"
        alphabet_class = "alphabet_active" if current_letter == letter
        alphabet += "<a class='#{alphabet_class}' href='##{class_name}_#{letter}'>#{letter}</a> "
      end
    end
    alphabet.html_safe
  end

  def show_alphabetized_list_of_items(alphabetized_list_of_items, class_name)
    content = ''
    available_letters = alphabetized_list_of_items.keys
    ("a".."z").each do |current_letter|
      if available_letters.include? current_letter
        content += "<h3 class='alphabet' id='#{class_name}_#{current_letter}'>"
          content += show_alphabet(available_letters, current_letter, class_name)
        content += "</h3>"
        alphabetized_list_of_items[current_letter].sort{|a1,a2| a1.name.downcase <=> a2.name.downcase}.each do |item|
          content += "<div class='row #{class_name}_row'>"
            content += "<div class='column #{class_name}_name small-3'>"
              content += item.name
            content += "</div>"
            content += "<div class='column #{class_name}_description small-9'>"
              content += item.description
              content += item.related_words_text('Gerelateerde begrippen: ')
            content += "</div>"
          content += "</div>"
        end
      end
    end
    content.html_safe
  end



end
