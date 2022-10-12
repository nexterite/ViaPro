# coding: utf-8

import redis
import log

log._logger.info("Start of the program for delete_content")

# Connexion au serveur redis
c = redis.ConnectionPool(host='127.0.0.1', port='6379', db=0,)
r = redis.StrictRedis(connection_pool=c)


# Debut de la transaction
p = r.pipeline()

if r.exists("disruption:roadworks") == 1:
    p.delete(*r.keys('disruption:roadworks'))
if r.exists("disruption:roadclosure") == 1:
    p.delete(*r.keys('disruption:roadclosure'))
if r.exists("roadclosure_list") == 1:
	p.delete(*r.keys('roadclosure_list'))
if r.exists("roadworks_list") == 1:
    p.delete(*r.keys('roadworks_list'))
if r.exists("roadworks-id") == 1:    
    p.delete(*r.keys('roadworks-id'))
if r.exists("roadclosure-id") == 1:
    p.delete(*r.keys('roadclosure-id'))

# End of transaction
p.execute()

print("All keys in condition deleted")


log._logger.info("End of the program")
log._logger.info("-----------------------------------------------------------------------------------------")
