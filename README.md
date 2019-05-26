## Configurar volumes para cluster K8S do WSO2 Identity Server no Mac OS

1. Acessar a pasta /Volumes e crias as seguintes pastas
	- /Volumes/wso2is-5.7.0/is/mysql
	- /Volumes/wso2is-5.7.0/is/repository
	- /Volumes/wso2is-5.7.0/is/deployment
	- /Volumes/wso2is-5.7.0/is/deployment/client
	- /Volumes/wso2is-5.7.0/is/deployment/server

2. Alterar a permissão das pastas de Volume:
    ``` chmod -R 755 /path/to/directory ```

3. Alterar o grupo das pastas de Volume:

    OBS: antes veja o seu usuário e grupo com oseguinte comando:
	
    ```id``` 

    resultado:

	```uid=501(fabio) gid=20(staff) groups=20(staff),12(everyone),61(localaccounts),79(_appserverusr),80(admin),81(_appserveradm),98(_lpadmin),701(com.apple.sharepoint.group.1),33(_appstore),100(_lpoperator),204(_developer),250(_analyticsusers),395(com.apple.access_ftp),398(com.apple.access_screensharing),399(com.apple.access_ssh)```

    então execute o comando:

    ``` chown -R uid:gid /path/to/directory ``` com o chown para uid:gid - de acordo com o exemplo acima - no meu caso fabio:staff

4. Copiar as aplicações WEB do WSO2 Identity Server para a pasta /Volumes/wso2is-5.7.0/is/deployment/server/webapps	

5. Copiar os arquivos do banco MySQL para /Volumes/wso2is-5.7.0/is/mysql

6. Executar o script /k8s/scripts/deploy.sh
	- Configurar usuário que tenha acesso a subscrição WSO2 para realizar o download das imagens.
  - SE NÃO TIVER A SUBSCRIÇÃO, você pode utilizar imagens publicas open-source ou criar a sua própria.


Referências de configurção do K8S Dashboard: http://collabnix.com/kubernetes-dashboard-on-docker-desktop-for-windows-2-0-0-3-in-2-minutes/

Notas Adicionais: 

    Executar o proxy para acessar o dashboard:
    
    ```kubectl proxy```

    Como obter o token para acessar o kubernetes dashboard: 

    ``` kubectl -n kube-system describe secret default ```
