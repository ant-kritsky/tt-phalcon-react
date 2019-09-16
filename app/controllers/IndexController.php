<?php

use Phalcon\Forms\Element\Text;
use Phalcon\Mvc\View;
use Phalcon\Forms\Form;
use Phalcon\Validation\Message;
use Phalcon\Validation\Validator\StringLength;

class IndexController extends ControllerBase
{
    public function initialize()
    {
        $this->tag->setTitle('Определение погоды');
    }

    public function indexAction()
    {
        $form = $this->getQueriesForm();
        $this->view->form = $form;
        $queries = Queries::query()
            ->orderBy('id DESC')
            ->execute()->toArray();
        $queries = array_map(function ($queryRow) {
            return unserialize($queryRow['city']);
        }, $queries);
        $this->view->queries = json_encode($queries);
    }

    /**
     * Определяет погоду по переданному наименованию города.
     */
    public function queryAction()
    {
        $this->view->disable();
        // Контроллер предназначен только для ajax завпросов.
        // Поэтому при прямом запросе редиректим на главную.
        if ($this->request->isAjax() != true) {
            $this->response->redirect('/');
        }
        $form = $this->getQueriesForm();
        if (!empty($lat = $this->request->get('lat')) && !empty($lon = $this->request->get('lon'))) {
            // Изем по координатам.
            $searchByPosition = true;
            $queryKey = "$lat,$lon";
        } else {
            // Изем по наименованию города.
            $cityName = $this->request->getPost('city');
            $searchByPosition = false;
            $queryKey = $cityName;
        }
        // Есть результат в кэше.
        if ($queryKey && null !== $city = $this->cache->get($queryKey)) {
            echo json_encode($city);
        } else {
            // Ищем по координатам.
            if ($searchByPosition) {
                $city = City::getByPosition($lat, $lon);
                // Координаты не переданы. Проверяем форму поиска по наименованию города.
            } else if ($form->isValid($this->request->getPost())) {
                $city = City::getByName($cityName);
                // Форма не валидна - выводим ошибки валидаторов.
            } else {
                $errors = [];
                $messages = $form->getMessages();
                /** @var Message $message */
                foreach ($messages as $message) {
                    $errors[] = $message->getMessage();
                }
                echo json_encode(['error' => implode('<br />', $errors)]);
                exit;
            }

            // Запрос к API прошел с ошибкой.
            if ($city->status != 200) {
                switch ($city->message) {
                    case 'city not found':
                        $city->error = 'Город не найден';
                        break;
                    default:
                        $city->error = $city->message;
                        break;
                }
            }

            echo json_encode($city);
            $query = new Queries();
            $query->value = $city->name;
            $query->response = $city->response;
            $query->city = serialize($city);
            $query->save();
            $this->cache->save($queryKey, $city);
        }

    }

    /**
     * Возвращает объект формы.
     * @return Form
     */
    protected
    function getQueriesForm()
    {
        $form = new Form(new Queries());
        $name = new Text('city', [
            'id' => 'cityName',
            'className' => 'form-control mr-md-2  col-md-5',
            'maxLength' => 70,
            'placeholder' => 'Введите город'
        ]);
        $name->addValidator(
            new StringLength([
                'min' => 3,
                'messageMinimum' => 'Введите не менее 3-х символов',
            ])
        );
        $form->add($name);
        return $form;
    }
}

