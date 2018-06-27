/**
 * An apex page controller that exposes the change password functionality
 */
public with sharing class ChangePasswordController {
    public String oldPassword {get; set;}
    public String newPassword {get; set;}
    public String verifyNewPassword {get; set;}

    public PageReference changePassword() {
        //return Site.changePassword(newPassword, verifyNewPassword, oldpassword);
        //PageReference pr = Site.changePassword(newPassword, verifyNewPassword, oldPassword);
        PageReference pr = Site.changePassword(newPassword, verifyNewPassword, '');
        for (ApexPages.Message message : ApexPages.getMessages()) {
            System.debug(message.getSeverity() == ApexPages.Severity.ERROR);
            System.debug(message.getSeverity() == ApexPages.Severity.INFO);
        }
        return Page.changePassword;
    }

    public ChangePasswordController() {}

    public static testMethod void testChangePasswordController() {
        // Instantiate a new controller with all parameters in the page
        ChangePasswordController controller = new ChangePasswordController();
        controller.oldPassword = '123456';
        controller.newPassword = 'qwerty1';
        controller.verifyNewPassword = 'qwerty1';

        System.assertEquals(controller.changePassword(),null);
    }
}