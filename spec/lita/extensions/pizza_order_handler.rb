class PizzaOrderHandler < Lita::Handler
  route(/^order$/, :order, command: true, multi_question: PizzaOrderQuestion)
  route(/^menu$/, :menu, command: true)
  route(/^message$/, :message, command: true, multi_question: OriginalMessageQuestion)

  def menu(response)
    menus = "tomato teriyaki ebi-mayo"
    response.reply menus
  end

  def order(response)
    # nothing
  end

  def message(response)
    # nothing
  end
end
