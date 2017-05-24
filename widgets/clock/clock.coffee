class Dashing.Clock extends Dashing.Widget

  ready: ->
    setInterval(@startTime, 500)

  startTime: =>
    today = new Date()

    daysFin = ['Sunnuntai','Maanantai','Tiistai','Keskiviikko','Torstai','Perjantai','Lauantai','Sunnuntai'] 
    monthsFin = ['','Tammikuuta','Helmikuuta','Maaliskuuta','Huhtikuuta','Toukokuuta','Kesäkuuta','Heinäkuuta','Elokuuta','Syyskuuta','Lokakuuta','Marraskuuta','Joulukuuta'] 

    h = today.getHours()
    m = today.getMinutes()
    s = today.getSeconds()
    m = @formatTime(m)
    s = @formatTime(s)

    date = today.getDate()
    day = today.getDay()
    dayStr = daysFin[day]
    month = today.getMonth()
    monthStr = monthsFin[month]

    @set('time', h + ":" + m)
    @set('weekday', dayStr)
    @set('date',  date + '. ' + monthStr)

  formatTime: (i) ->
    if i < 10 then "0" + i else i
