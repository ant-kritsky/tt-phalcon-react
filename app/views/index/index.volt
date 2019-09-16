<div class="page-header">
    <h3>Узнать погоду в любом городе мира!</h3>
</div>
<div id="weather"></div>

<script type="text/babel">
    var queriesLimit = 10;
    class Map extends React.Component {
        constructor (props, context) {
            super(props, context);
            super(props);
            this.state = {
                display: 'none'
            }

            this.onScriptLoad = this.onScriptLoad.bind(this)
        }

        async getWeather (parentComponent) {
            const positions = window.marker.getPosition();
            const url = $("#getWeather").attr('action') + `?lat=${positions.lat()}&lon=${positions.lng()}`;
            const MapComponent = this;
            MapComponent.setState({display: 'block'});
            let response = await fetch(url);
            if (response.ok) {
                const data = await response.json();
                parentComponent.setState({data: data});
                var action = {
                    type: 'ADD_QUERY',
                    data: data
                };
                parentComponent.props.dispatch(action);
                MapComponent.setState({display: 'none'});
            } else {
                console.log("Ошибка HTTP: " + response.status);
            }
        }

        onScriptLoad() {
            const MapComponent = this;
            const map = new window.google.maps.Map(
                document.getElementById(this.props.id),
                this.props.options
            );
            map.addListener('click', function(e) {
                var setMarker = function(location, map) {
                    if (window.marker == null)
                    {
                        // console.log(location);
                        window.marker = new google.maps.Marker({
                            position: location,
                            map: map
                        });
                    } else {
                        window.marker.setPosition(location);
                    }
                }
                setMarker(e.latLng, map);
                MapComponent.getWeather(MapComponent.props.onMapLoad);
            });
            window.myMap = map;
        }

        componentDidMount() {
            if (!window.google) {
                var s = document.createElement('script');
                s.type = 'text/javascript';
                s.src = `https://maps.google.com/maps/api/js?key=AIzaSyD0iqYu5MffapT-rBtaBaJiZGI341IvM58`;
                var x = document.getElementsByTagName('script')[0];
                x.parentNode.insertBefore(s, x);
                s.addEventListener('load', e => {
                    this.onScriptLoad()
                })
            } else {
                this.onScriptLoad()
            }
        }

        render() {
            return (
                <div>
                    <div id={this.props.id} style={ {
                        minWidth:'300px', width:'100%', height: '200px'
                    } } />
                    <div className="progress">
                        <div className="progress-bar progress-bar-striped progress-bar-animated" role="progressbar"
                           aria-valuenow="100" aria-valuemin="0" aria-valuemax="100" style={ {
                             width: '100%',
                             display: this.state.display
                           } }></div>
                    </div>
                </div>
            );
        }
    }
    // Возвращает описание погоды.
    function getDescription(data) {
        var weather = data.weather;
        return Object.values(weather)[0]['description'];
    }

    var CityInfo = React.createClass({
        render: function () {
            if (this.props.data.error) {
                return (
                    <div className="text-danger">
                        {this.props.data.error ? this.props.error : ''}
                    </div>
                )
            } else if (this.props.data.name) {
                var prepareTemp = function (temp) {
                    return temp
                        ? parseInt(temp)/10
                        : ''
                }
                this.temp = prepareTemp(this.props.data.main.temp);
                var description = getDescription(this.props.data);
                return (
                    <div>
                        <a name="cityInfo" id="cityInfo"/>
                        <div className="block"><h4>Информация о погоде:</h4></div>
                        <div className="row">
                            <div className="col-md-4">Местоположение:</div>
                            <div className="col-md-7">{this.props.data.name}</div>
                            <div className="col-md-4">Погода:</div>
                            <div className="col-md-7">{this.temp} °C ({description})</div>
                            <div className="col-md-4">Ветер:</div>
                            <div
                                className="col-md-7">{this.props.data.wind.speed} {this.props.data.wind.deb} м/с
                            </div>
                        </div>
                    </div>
                );
            } else {
                return (
                    <div/>
                )
            }
        }
    });

    class SearchError  extends React.Component {
        render() {
            return (
                <div>
                {
                    this.props && this.props.data && this.props.data.error && <div className="text-danger">
                        {this.props.data.error}
                    </div>
                }
                </div>
            );
        }
    };

    function QuiresList(queries) {
        const listItems = queries.map(
            function(quiry, i) {
                var description = getDescription(quiry);
                if (i < queriesLimit) return (
                    <li key={i}>{quiry.name}: {parseInt(quiry.main.temp)/10} °C ({description})</li>
                )
            }
        );
        return (
            <ul>{listItems}</ul>
        );
    }

    const mapStateToProps = (state) => {
        return {
            queries: state.queriesList
        }
    }

    class WeatherComponent extends React.Component {
        constructor (props, context) {
            super(props, context);
            this.state = {
                isToggleOn: true,
                data: {}
            }
            this.queries = props.queries;
            this.handleSearch = this.handleSearch.bind(this);
        }

        handleSearch(e) {
            e.preventDefault();
            const button = this;
            const cityName = e.target.parentElement.children[0].value;

            button.setState({isToggleOn: false});
            $.post($("#getWeather").attr('action'), {city: cityName}, function (data) {
                button.state.data = data;
                $("#cityName").removeClass('is-invalid');
                if (data.error) {
                    $("#cityName").addClass('is-invalid');
                } else {
                    $("#cityName").val('');
                    $("#cityInfo").focus();
                }
                button.setState({isToggleOn: true});
                button.setState({data: data});
                var action = {
                    type: 'ADD_QUERY',
                    data: data
                };
                button.props.dispatch(action);
            }, 'json');
        }
        componentDidMount() {
            $('form').submit(function () {
                $('searchWeather').click();
                return false;
            });

            var queries = this.props.queries;
            $("#cityName").autocomplete({
                minLength: 1,
                source: function (request, response) {
                    var array = $.map(queries, function (item) {
                        return {
                            label: item.name,
                            value: item.name
                        }
                    });
                    response($.ui.autocomplete.filter(array, request.term));
                }

            });
        }
        render() {
            var quiresList = QuiresList(this.props.queries);
            return (
                <div>
                        {{form('/index/query', 'className': 'form-inline md-form', 'id': 'getWeather')}}
                        {{form.render('city')}}
                        <button onClick={el => this.handleSearch(el)} className="btn btn-success col-md-4" id="searchWeather">
                            {this.state.isToggleOn ? 'Узнать погоду!' : 'Узнаем. Подождите...'}
                        </button>
                        {{endForm()}}
                    <SearchError data={this.state.data} />
                    <div className="block">
                        <h3>Либо выберите место на карте:</h3>
                        <Map id="myMap"
                            options={
                                {
                                    center: { lat: 41.0082, lng: 28.9784 }, zoom: 8
                                }
                            }
                            onMapLoad={this}
                        />
                        <div className="row">
                            <div className="col-md-6">
                                <CityInfo data={this.state.data}/>
                            </div>
                            <div className="col-md-6">
                                <div className="block"><h4>Последние {queriesLimit} уникальных запросов:</h4></div>
                                {quiresList}
                            </div>
                        </div>
                    </div>
                </div>

            );
        }
    }

    const appReducer = (state = {queriesList: []}, action) => {
        let queries = state.queriesList.slice();
        // console.log('Actions', action);

        switch (action.type) {
            case 'ADD_QUERY':
                var query = action.data;
                queries.unshift(query);
                break;
        }

        const newState = {
            queriesList: queries
        }
        console.log('Current State', newState);
        return newState;
    }

    let store = Redux.createStore(appReducer, {
        queriesList: {{queries}}
    }, window.devToolsExtension ? window.devToolsExtension() : undefined);

    const WeatherApp = ReactRedux.connect(
        mapStateToProps
    )(WeatherComponent);

    ReactDOM.render(
        <ReactRedux.Provider store={store}>
            <WeatherApp/>
        </ReactRedux.Provider>,
        document.getElementById('weather')
    );

    if (window.devToolsExtension) {
        window.devToolsExtension.open();
    }

</script>