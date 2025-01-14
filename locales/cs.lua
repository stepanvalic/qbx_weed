local Translations = {
    error = {
        process_canceled = "Proces zrušen",
        plant_has_died = "Rostlina uhynula. Stiskněte ~r~ E ~w~, abyste ji odstranili.",
        cant_place_here = "Nemůžete to umístit sem",
        not_safe_here = "Tady to není bezpečné, zkuste to ve svém domě",
        not_need_nutrition = "Rostlina nepotřebuje živiny",
        this_plant_no_longer_exists = "Tato rostlina již neexistuje?",
        house_not_found = "Dům nenalezen",
        you_dont_have_enough_resealable_bags = "Nemáte dostatek znovuzapouzdřovacích sáčků",
    },
    text = {
        sort = 'Seřadit:',
        harvest_plant = 'Stiskněte ~g~ E ~w~, abyste rostlinu sklízeli.',
        nutrition = "Výživa:",
        health = "Zdraví:",
        harvesting_plant = "Sklízení rostliny",
        planting = "Vysazování",
        feeding_plant = "Krmení rostliny",
        the_plant_has_been_harvested = "Rostlina byla sklizena",
        removing_the_plant = "Odstranění rostliny",
    },
}

if GetConvar('qb_locale', 'en') == 'cs' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
--translate by stepan_valic