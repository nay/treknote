class WelcomeController < ApplicationController
  stylesheet 'welcome'
  def index
    @title = "Trek Note - 行った場所を記録しよう！"
  end
end
