class HealthcheckController < ApplicationController
    def show
        head :ok
    end
end
