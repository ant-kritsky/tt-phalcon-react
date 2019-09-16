<?php

use Phalcon\Http\Request;

/**
 * Class CityCoords Класс координат города.
 */
class CityCoords
{
    public $lot = null;
    public $lat = null;
}

/**
 * Class CityWeather Класс погодных условий (Rain, Mist, ...).
 */
class CityWeather
{
    public $id = null;
    public $main = null;
    public $description = null;
    public $icon = null;
}

/**
 * Class CityWind Класс свойств ветра.
 */
class CityWind
{
    public $speed = null;
    public $deg = null;
}

/**
 * Class CityMain Класс основных параметров погоды.
 */
class CityMain
{
    /**
     * @var float Среднесуточная температура.
     */
    public $temp = null;
    /**
     * @var int Атмосферное давление.
     */
    public $pressure = null;
    /**
     * @var int Влажность..
     */
    public $humidity = null;
    /**
     * @var float Минимальная температура.
     */
    public $temp_min = null;
    /**
     * @var float Максимальная температура.
     */
    public $temp_max = null;
}

/**
 * Class City Класс города.
 */
class City
{
    /**
     * @var HTTP Status
     */
    public $status = null;
    /**
     * @var null Наименование местоположения.
     */
    public $name = null;
    /**
     * @var string|null Ошибка запроса.
     */
    public $error = null;
    /**
     * @var CityCoords
     */
    public $coord = null;
    /**
     * @var CityWeather[]
     */
    public $weather = [];
    /**
     * @var CityWind
     */
    public $wind = null;
    /**
     * @var CityMain
     */
    public $main = null;

    /**
     * @var null Хранит результат ответа от API сервера.
     */
    public $response = null;

    public static $apiUrl = "http://api.openweathermap.org/data/2.5/weather?APPID=153276fd2d017ceeae8ac4fa34ad4c6c&lang=ru&";

    /**
     * @param $urlApi Адрес API по которому запрашиваются данные погоды.
     * @return City
     */
    public function getCity($urlApi)
    {
        $curl = curl_init($urlApi);
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_FAILONERROR, false);
        $this->response = curl_exec($curl);
        $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
        $this->status = $httpCode;
        if (false == $error = curl_error($curl)) {
            $data = json_decode($this->response);
            // Сохраняем данные погоды в текущий объект.
            foreach ((array)$data as $key => $value) {
                $this->$key = $value;
            }
        } else {
            $this->error = $error;
        }
        curl_close($curl);
        return $this;
    }

    public static function getByName($cityName)
    {
        $urlApi = self::$apiUrl . "q=" . $cityName;
        $city = new self();
        return $city->getCity($urlApi);
    }

    public static function getByPosition($lat, $lon)
    {
        $urlApi = self::$apiUrl . "lat=$lat&lon=$lon";
        $city = new self();
        return $city->getCity($urlApi);
    }
}