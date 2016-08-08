module Api
  class GuarantesController < ApplicationController

    def index
      if request_version == 1
        @guarantes = Guarante.unprocess(DateTime.parse("2016-09-11 12:30:00").to_date)
      end
    end

  end
end
