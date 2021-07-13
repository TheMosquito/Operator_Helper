# Operator_Helper

This project is glue code that I use to simplify creation of an Operator for Open-Horizon deployment onto Kubernetes clusters. I wrote this because I have difficulty following the [official Open Horizon documentation](https://github.com/open-horizon/examples/tree/master/edge/services/nginx-operator) for their operator example. I hope you will find this helpful too, but if you run into troubles please go to the official documentation and follow the procedures there.

I built this to use with RedHat's OpenShift Container Platform (OCP) but it should still work for other Kubernetes environments too. I also built this for the IBM Edge Application Manager commercial deployment of Open Horizon, but it should work for other (e.g., open source only) Open Horizon deployments too. Also, I used an Open Horizon "deployment pattern" style of deployment here, but the "policy" style deployment will of course also work fine. I created some example policy files to help you go that route. Edit them to have more appropriate properties and constraints for your application.

When you are ready to begin, run `make`. That will give you some brief info, tell you to edit the above files, and then also tell you what command to run next. The next command will then lead you to the following step, and so on. If you prefer to see more instruction first, please read on...

A typical workflow for this helper is:
 - edit some files and fill in a few fields to provide info for the scripts
 - run `make init`
 - **optionally** edit files as desired to add more Kubernetes features
 - run `make build` to create the operator
 - run `make service` to publish the operator as an Open Horizon service
 - run `make pattern` to publish an Open horizon deployment pattern for this service
 - then run `oc login` to any cluster that has an Open Horizon agent, and run `make register`

Here is a more detailed walk-through:

0. Prerequisites:
   - install docker, make, and curl on your development machine
   - install operator-sdk, v0.19.4 on your development machine
   - install the Open Horizon CLI package on your development machine
   - get an account on an Open Horizon Management Hub, and get your credentials onto your development machine

1. Create your workload container, push it to a Docker repo, and test it. I used this one from another of my GitHub accounts: https://github.com/MegaMosquito/web-hello). If you have your own container ready, and pushed, you can skip this. If you don't you can use mine if you like.

2. Clone this Operator_Helper repo, then run `make`.

3. The output of that command will tell you to provide information about your workload container, etc. You must fill in at least all of the empty/undefined variables in both `my_env` and `horizon/my_hzn_env` files. I hard-coded TCP port 8000 for my example web service, so you will also need to edit that number if your service binds to a different container port. I also set an environment variable called `MY_VAR` for my example. You can also change that if you wish (but ignore it, don't remove it, if you don't need anything in your container's environment). Note that the you need to provide your Open Horizon credentials in `horizon/my_hzn_env`. You will get these from your Open Horizon Management Hub administrator. Once both of those files are ready with your info, move on to the next step.

4. Run `make init`. This step will use `operator-sdk` to create a mostly-blank Operator you can deploy with Open Horizon

5. Edit the files in the `src` directory as necessary for your workload container. You need to know a little about Kubernetes to edit things there. For my example web-hello container I did not need to edit these at all. If you need to add resources (e.g., GPU resources) to your "deployment", you will need to add them in `src/templates/deployment.j2`. Some other files you may want to review or edit are shown below:
   - src/templates/service.j2
   - src/templates/route.j2
   You may also add new `roles` directory files here if you wish, and they will be copied under the `roles` directory in the generated operator. When you are satisfied with the files in the `src` directory, move on to the next step.

6. When you are ready, run `make build`. This will build your Operator, and push it to DockerHub (I hard coded that Docker Repository, but feel free to edit this in the Makefile if you prefer `quay.io` for example. Note that if you have followed my suggestion above, and edited only files in the `src` directory then everything in the generated Operator directory is just that -- completely derived. Nothing worth saving is in there.

7. After building and pushing your Operator in the previous step, you can `oc login...` to any cluster to test it. To deploy it, use `make test`. This will run a bunch of `kubectl` commands to deploy your resources into the cluster and verify it works correctly when manually deployed. When your testing is complete, run `make stop` and move on to the next step.

8. Now that your Operator has been tested and you feel it is ready for deployment, you can go ahead and run `make service` to publish it for use with Open Horizon use.

9. Then you can publish an Open Horizon deployment pattern for this service by running `make pattern`. Or if you prefer, you can use a deployment policy approach (though that will require some edits).

10. Once your pattern is published then you can `oc login...` to any cluster **where the Open Horizon Agent is installed** and run `make register`. Note that if you use this approach to register multiple clusters then you will need to edit the **HZN_EXCHANGE_NODE_AUTH** environment variable before registering each one or you will end up overwriting the same node registration.

Anyway, that's it! After you register, then an Open Horizon AgBot will reach out to the cluster Agent, and negotiate to collaborate on the software deployment. Soon you should see your pod being deployed and you can again test it as you did when you manually deployed it.


