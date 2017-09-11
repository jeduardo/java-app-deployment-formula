===========================
java-app-deployment-formula
===========================

A saltstack formula created to deploy a Java-based application into a single
machine or into a machine cluster. 

.. notes::
    It is assumed that the application will be deployed from a runnable JAR.
    The formula depends on the `sun-java-formula
    <https://github.com/saltstack-formulas/sun-java-formula/>`_.
    The formula will run the application using systemd.


Available states
================

.. contents::
    :local:

``init``
--------

This is all that is required to deploy the application. It will download the 
artifact from a remote location and deploy it using systemd.
