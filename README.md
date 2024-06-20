# Step-wise_Sequential_Phase_Partition
Source code for "step-wise sequential phase partition (SSPP) algorithm based statistical modeling and online process monitoring".   
The details of this algorithm can be found in    
 [Zhao, Chunhui, and Youxian Sun. "Step-wise sequential phase partition (SSPP) algorithm based statistical modeling and online process monitoring." Chemometrics and Intelligent Laboratory Systems, 125: 109-120, 2013.](https://www.sciencedirect.com/science/article/pii/S0169743913000579)

#### Example:  
Please see 'demo.m' for how to use this algorithm.
The data used in this paper is not allowed to be shared. You should prepare your data and change the parameters accordingly before running 'demo.m'.

#### Note:
* We use monitoring methods SFA/PCA as base models and monitoring statistics as merge indicators to capture process characteristics and divide data into different modes. You can change the base model and statistics according to your needs. If so, you should prepare your own class based on the 'base_model/SFA_class.m'.
* If you want to segment and rearrange data for other tasks rather than monitoring tasks, you simply need to adjust the methods and indicators accordingly.
* The 'demo.m' is an example showing how to use divided data for monitoring. You can use divided data for other purposes. If so, you should replace the 'utils/monitoring.m' function with your own function. 


#### All rights reserved, citing the following paper is required for reference:   
[1] C. Zhao, and Y. Sun. Step-wise sequential phase partition (SSPP) algorithm based statistical modeling and online process monitoring. Chemometrics and Intelligent Laboratory Systems, 125: 109-120, 2013.

[2] C. Zhao, F. Wang, N. Lu, and M. Jia. Stage-based soft-transition multiple PCA modeling and on-line monitoring strategy for batch processes. Journal of Process Control, 2007, 17(9), 728–741.
