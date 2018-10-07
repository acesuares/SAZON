class BestandsController < InlineFormsController
  set_tab :bestand

  def download
    @bestand = Bestand.find_by(slug: params[:slug])
    return redirect_to '/view/not_found' if @bestand.nil?
    send_data @bestand.file.data, :filename => @bestand.file.filename, :type => @bestand.content_type
  end
end
