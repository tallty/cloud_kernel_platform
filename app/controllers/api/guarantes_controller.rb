module Api
  class GuarantesController < ApplicationController

    def index
      if request_version == 1
        datetime = params[:date]
        @guarantes = Guarante.unprocess(DateTime.parse(datetime).to_date)
      end
    end

  end
end
