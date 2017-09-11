{# Including the Java runtime #}
include:
  - sun-java
  - sun-java.env

{%- set directory = salt['pillar.get']('application:deploy:directory', '/home/application') %}
{%- set user = salt['pillar.get']('application:deploy:user') %}
{%- set group = salt['pillar.get']('application:deploy:group') %}
{%- set service = salt['pillar.get']('application:deploy:service') %}
{%- set repository = salt['pillar.get']('application:deploy:repository') %}
{%- set artifact_path = salt['pillar.get']('application:deploy:artifact_path') %}
{%- set artifact_name = salt['pillar.get']('application:deploy:artifact_name') %}
{%- set artifact_checksum = salt['pillar.get']('application:deploy:artifact_checksum') %}

application user is present:
  user.present:
    - name: {{ user }}
    - system: True

application group is present:
  group.present:
    - name: {{ group }}

application directory is present:
  file.directory:
    - name: {{ directory }}
    - user: {{ user }}
    - group: {{ group }}
    - require:
      - user: {{ user }}
      - group: {{ group }}

deploy app artifact:
  file.managed:
    - name: {{ directory }}/{{ artifact_name }}
    - source: {{ artifact_path }}
    - source_hash: {{ artifact_checksum }}
    - user: {{ user }}
    - group: {{ group }}
    - require:
      - user: {{ user }}
      - group: {{ group }}

deploy app systemd unit:
  file.managed:
    - name: /etc/systemd/system/{{ service }}.service
    - context:
        service: {{ service }}
        directory: {{ directory }}
        user: {{ user }}
        group: {{ group }} 
        artifact: {{ artifact_name }}
    - source: salt://deployment/files/application.service.j2
    - template: jinja
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: /etc/systemd/system/{{ service }}.service

enable application service:
  service.running:
    - name: {{ service }}
    - enable: True
    - require:
      - file: deploy app systemd unit

deploy environment file:
  file.managed:
    - name: {{ directory }}/.env
    - user: {{ user }}
    - group: {{ group }}
    - chmod: 0400
    - contents: |
        # Salt managed configuration
        {%- for entry, value in salt['pillar.get']('application:config', '{}').items() %}
        APP_{{ entry | upper }}={{ value }}
        {%- endfor %}

restart application on redeploy or service changes:
  service.running:
    - name: {{ service }}
    - restart: True
    - order: last
    - watch:
      - file: /etc/systemd/system/{{ service }}.service
      - file: {{ directory }}/{{ artifact_name }}
      - file: {{ directory }}/.env

issue event when application is deployed:
  event.send:
    - name: application/service/register
    - data:
        application:
          service:
            name: {{ service }}
            id: {{ grains['host'] }}
            address: {{ grains['fqdn_ip4'][0] }}
            port: {{ salt['pillar.get']('application:config:port', 5000) }}
            endpoint: {{ salt['pillar.get']('application:check:endpoint') }}
            tags: {{ salt['pillar.get']('application:check:tags') }}
            interval: {{ salt['pillar.get']('application:check:interval', '30s') }}

           
