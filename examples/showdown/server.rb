require 'blix/rest'

Blix::Rest.set_erb_root('views')

class Controller < Blix::Rest::Controller

  get '/:title', :accept=>:html do
    @title = params[:title]
    @members = [
      {name: "Chris McCord"},
      {name: "Matt Sears"},
      {name: "David Stump"},
      {name: "Ricardo Thompson"}
    ]
    render_erb :index, :layout=>'layout'
  end

end
