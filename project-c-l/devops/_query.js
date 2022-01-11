/* eslint-disable no-undef */
// ######################################################################
// ########### Example of query for the sh mongoExecute.sh ##############
// ######################################################################

db.getCollection("databases").find({})
    .count();
