local Translations = {
    error = {
        no_money = 'Dinheiro insuficiente',
        too_far = 'Você está muito longe do seu carrinho de cachorro-quente',
        no_stand = 'Você não tem um carrinho de cachorro-quente',
        cust_refused = 'Cliente recusado!',
        no_stand_found = 'Seu carrinho de cachorro-quente não foi encontrado, você não receberá seu depósito de volta!',
        no_more = 'Você não tem mais %{value} sobre isso perante o conselho',
        deposit_notreturned = 'Você não tinha um Carrinho de Cachorro-Quente',
        no_dogs = 'Você não tem nenhum cachorro-quente',
    },
    success = {
        deposit = 'Você pagou um depósito de $%{deposit}!',
        deposit_returned = 'Seu depósito de $%{deposit} foi devolvido!',
        sold_hotdogs = '%{value} x Cachorro-quente(s) vendido(s) por $%{value2}',
        made_hotdog = 'Você fez um %{value} Cachorro-Quente',
        made_luck_hotdog = 'Você fez %{value} x %{value2} Cachorros-Quentes',
    },
    info = {
        command = "Excluir Carrinho (Apenas Admin)",
        blip_name = 'Carrinho de Cachorro-Quente',
        start_working = '[E] Começar a Trabalhar',
        start_work = 'Começar a Trabalhar',
        stop_working = '[E] Parar de Trabalhar',
        stop_work = 'Parar de Trabalhar',
        grab_stall = '[~g~G~s~] Pegar Barraca',
        drop_stall = '[~g~G~s~] Soltar Barraca',
        grab = 'Pegar Barraca',
        prepare = 'Preparar Cachorro-Quente',
        toggle_sell = 'Alternar Venda',
        selling_prep = '[~g~E~s~] Preparar Cachorro-Quente [Venda: ~g~Vendendo~w~]',
        not_selling = '[~g~E~s~] Preparar Cachorro-Quente [Venda: ~r~Não Vendendo~w~]',
        sell_dogs = '[~g~7~s~] Vender %{value} x Cachorros-Quentes por $%{value2} / [~g~8~s~] Recusar',
        sell_dogs_target = 'Vender %{value} x Cachorros-Quentes por $%{value2}',
        admin_removed = "Carrinho de Cachorro-Quente Removido",
        label_a = "Perfeito (A)",
        label_b = "Raro (B)",
        label_c = "Comum (C)",
        toggle_work = "Alternar Trabalho",
        selling = "Agora você está vendendo cachorros-quentes",
        no_selling = "Você não está mais vendendo cachorros-quentes",
        decline_offer = 'Recusar oferta',
    },
    keymapping = {
        gkey = 'Soltar carrinho de cachorro-quente',
        
    }
}

if GetConvar('qb_locale', 'en') == 'pt-br' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
