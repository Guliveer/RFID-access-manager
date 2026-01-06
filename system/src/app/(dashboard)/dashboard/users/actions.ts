'use server';

import { createClient as createServerClient } from '@/utils/supabase/server';
import { supabaseAdmin } from '@/utils/supabase/admin';

interface CreateUserParams {
  email: string;
  password: string;
  full_name: string;
  role: 'user' | 'admin';
}

interface CreateUserResult {
  success: boolean;
  error?: string;
  user?: {
    id: string;
    email: string;
  };
}

interface DeleteUserResult {
  success: boolean;
  error?: string;
}

interface ToggleUserActiveResult {
  success: boolean;
  error?: string;
  isActive?: boolean;
}

interface ResetPasswordResult {
  success: boolean;
  error?: string;
}

interface AuthenticatedUser {
  id: string;
  role: string;
}

type UserRole = 'root' | 'admin' | 'user';

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const MIN_PASSWORD_LENGTH = 6;

async function getAuthenticatedUserWithRole(): Promise<{ user: AuthenticatedUser | null; error: string | null }> {
    const supabase = await createServerClient();
    const {
        data: { user: currentUser },
        error: authError
    } = await supabase.auth.getUser();

    if (authError || !currentUser) {
        return { user: null, error: 'Unauthorized' };
    }

    const { data: userData, error: userError } = await supabase.from('users').select('role').eq('id', currentUser.id).single();

    if (userError || !userData) {
        return { user: null, error: 'User not found' };
    }

    return { user: { id: currentUser.id, role: userData.role }, error: null };
}

async function getTargetUserRole(userId: string): Promise<{ role: UserRole | null; error: string | null }> {
    const supabase = await createServerClient();
    const { data: targetUser, error: targetError } = await supabase.from('users').select('role').eq('id', userId).single();

    if (targetError || !targetUser) {
        return { role: null, error: 'Target user not found' };
    }

    return { role: targetUser.role as UserRole, error: null };
}

function canManageLowerRole(currentRole: string, targetRole: string): boolean {
    return (currentRole === 'root' && targetRole !== 'root') || (currentRole === 'admin' && targetRole === 'user');
}

function isValidEmail(email: string): boolean {
    return EMAIL_REGEX.test(email);
}

function isValidPassword(password: string): boolean {
    return password.length >= MIN_PASSWORD_LENGTH;
}

export async function createUser(params: CreateUserParams): Promise<CreateUserResult> {
    try {
        const { user: currentUser, error: authError } = await getAuthenticatedUserWithRole();

        if (authError || !currentUser) {
            return { success: false, error: authError || 'Unauthorized' };
        }

        const currentUserRole = currentUser.role;

        if (currentUserRole !== 'root' && currentUserRole !== 'admin') {
            return { success: false, error: 'Insufficient permissions' };
        }

        if (!isValidEmail(params.email)) {
            return { success: false, error: 'Invalid email format' };
        }

        if (!isValidPassword(params.password)) {
            return { success: false, error: 'Password must be at least 6 characters' };
        }

        let assignedRole: 'user' | 'admin' = 'user';
        if (currentUserRole === 'root' && params.role) {
            assignedRole = params.role;
        }

        const { data: authData, error: createError } = await supabaseAdmin.auth.admin.createUser({
            email: params.email,
            password: params.password,
            email_confirm: true,
            user_metadata: {
                full_name: params.full_name
            }
        });

        if (createError) {
            console.error('Error creating user:', createError);
            return { success: false, error: createError.message };
        }

        if (!authData.user) {
            return { success: false, error: 'Failed to create user' };
        }

        const { error: updateError } = await supabaseAdmin
            .from('users')
            .update({
                full_name: params.full_name,
                role: assignedRole
            })
            .eq('id', authData.user.id);

        if (updateError) {
            console.error('Error updating user profile:', updateError);
        }

        return {
            success: true,
            user: {
                id: authData.user.id,
                email: authData.user.email!
            }
        };
    } catch (error) {
        console.error('Unexpected error:', error);
        return { success: false, error: 'Internal server error' };
    }
}

export async function deleteUser(userId: string): Promise<DeleteUserResult> {
    try {
        const { user: currentUser, error: authError } = await getAuthenticatedUserWithRole();

        if (authError || !currentUser) {
            return { success: false, error: authError || 'Unauthorized' };
        }

        if (currentUser.role !== 'root') {
            return { success: false, error: 'Insufficient permissions' };
        }

        if (userId === currentUser.id) {
            return { success: false, error: 'Cannot delete your own account' };
        }

        const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(userId);

        if (deleteError) {
            console.error('Error deleting user:', deleteError);
            return { success: false, error: deleteError.message };
        }

        return { success: true };
    } catch (error) {
        console.error('Unexpected error:', error);
        return { success: false, error: 'Internal server error' };
    }
}

export async function toggleUserActive(userId: string, isActive: boolean): Promise<ToggleUserActiveResult> {
    try {
        const { user: currentUser, error: authError } = await getAuthenticatedUserWithRole();

        if (authError || !currentUser) {
            return { success: false, error: authError || 'Unauthorized' };
        }

        if (currentUser.role !== 'root' && currentUser.role !== 'admin') {
            return { success: false, error: 'Insufficient permissions' };
        }

        if (userId === currentUser.id) {
            return { success: false, error: 'Cannot change your own active status' };
        }

        const { role: targetRole, error: targetError } = await getTargetUserRole(userId);

        if (targetError || !targetRole) {
            return { success: false, error: targetError || 'Target user not found' };
        }

        if (!canManageLowerRole(currentUser.role, targetRole)) {
            return { success: false, error: 'Insufficient permissions' };
        }

        const { error: updateError } = await supabaseAdmin.from('users').update({ is_active: isActive }).eq('id', userId);

        if (updateError) {
            console.error('Error toggling user active status:', updateError);
            return { success: false, error: updateError.message };
        }

        return { success: true, isActive };
    } catch (error) {
        console.error('Unexpected error:', error);
        return { success: false, error: 'Internal server error' };
    }
}

export async function resetUserPassword(userId: string, newPassword: string): Promise<ResetPasswordResult> {
    try {
        const { user: currentUser, error: authError } = await getAuthenticatedUserWithRole();

        if (authError || !currentUser) {
            return { success: false, error: authError || 'Unauthorized' };
        }

        if (!isValidPassword(newPassword)) {
            return { success: false, error: 'Password must be at least 6 characters' };
        }

        const { role: targetRole, error: targetError } = await getTargetUserRole(userId);

        if (targetError || !targetRole) {
            return { success: false, error: targetError || 'Target user not found' };
        }

        if (!canManageLowerRole(currentUser.role, targetRole)) {
            return { success: false, error: 'Insufficient permissions' };
        }

        const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(userId, {
            password: newPassword
        });

        if (updateError) {
            console.error('Error resetting password:', updateError);
            return { success: false, error: updateError.message };
        }

        return { success: true };
    } catch (error) {
        console.error('Unexpected error:', error);
        return { success: false, error: 'Internal server error' };
    }
}
