class SampleHandler < Lita::Handler
  route(/^order$/, :order, command: true, multi_question: PizzaOrderQuestion)
  route(/^menu$/, :menu, command: true)
  route(/^message$/, :message, command: true, multi_question: OriginalMessageQuestion)
  route(/^last_select$/, :message, command: true, multi_question: LastSelectQuestion)

  def menu(response)
    menus = 'tomato teriyaki ebi-mayo'
    response.reply menus
  end

  def order(response)
    # nothing
  end

  def message(response)
    # nothing
  end
end
