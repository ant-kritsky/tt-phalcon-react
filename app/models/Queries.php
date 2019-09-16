<?php


class Queries extends \Phalcon\Mvc\Model
{
    /**
     * @Column(type="string", nullable=false)
     */
    public $value;
    /**
     * @Column(type="test", nullable=false)
     */
    public $response;
    /**
     * @Column(type="test", nullable=false)
     */
    public $city;

    public function initialize()
    {
        $this->setSource('queries');
    }
}